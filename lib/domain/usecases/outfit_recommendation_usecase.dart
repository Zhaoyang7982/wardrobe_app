import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../models/clothing.dart';
import '../models/outfit.dart';
import '../models/recommendation_day_context.dart';
import '../models/user_profile.dart';

/// 从环境注入的 AI 客户端配置（密钥不在代码中硬编码，由上层从 dotenv 等读取）
class AiClientConfig {
  const AiClientConfig({
    this.apiKey,
    this.baseUrl,
    this.model = 'gpt-4o-mini',
  });

  final String? apiKey;
  final String? baseUrl;
  final String model;

  bool get isComplete =>
      apiKey != null &&
      apiKey!.isNotEmpty &&
      baseUrl != null &&
      baseUrl!.isNotEmpty;
}

/// 单套推荐（若干件衣物）
class RecommendedOutfitBundle {
  const RecommendedOutfitBundle({
    required this.clothings,
    this.title,
    this.reason,
  });

  final List<Clothing> clothings;
  final String? title;
  final String? reason;
}

enum RecommendationPrimarySource { rule, ai }

/// 今日推荐聚合结果（至多 4 套）
class TodayRecommendationResult {
  const TodayRecommendationResult({
    required this.outfits,
    required this.seasonLabel,
    required this.primarySource,
    this.aiSkippedReason,
    this.dayContext,
  });

  final List<RecommendedOutfitBundle> outfits;
  final String seasonLabel;
  final RecommendationPrimarySource primarySource;

  /// AI 未启用或失败时的说明（便于 UI 提示，非错误）
  final String? aiSkippedReason;

  /// 由上层在联网拉取后注入；用于展示日期/天气说明并参与 AI 提示。
  final RecommendationDayContext? dayContext;

  TodayRecommendationResult copyWith({RecommendationDayContext? dayContext}) {
    return TodayRecommendationResult(
      outfits: outfits,
      seasonLabel: seasonLabel,
      primarySource: primarySource,
      aiSkippedReason: aiSkippedReason,
      dayContext: dayContext ?? this.dayContext,
    );
  }
}

/// 规则 + 可选 OpenAI 兼容接口的搭配推荐
class OutfitRecommendationUseCase {
  OutfitRecommendationUseCase({
    required this.loadAiConfig,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 28),
              ),
            );

  final AiClientConfig Function() loadAiConfig;
  final Dio _dio;

  static const _activeStatus = '在穿';

  /// 北半球：3–5 春，6–8 夏，9–11 秋，12–2 冬
  static String seasonForDate(DateTime date) {
    final m = date.month;
    if (m >= 3 && m <= 5) {
      return '春';
    }
    if (m >= 6 && m <= 8) {
      return '夏';
    }
    if (m >= 9 && m <= 11) {
      return '秋';
    }
    return '冬';
  }

  static bool clothingMatchesSeason(Clothing c, String seasonChar) {
    final s = c.season?.trim();
    if (s == null || s.isEmpty) {
      return true;
    }
    if (s.contains('四季') || s.contains('全年')) {
      return true;
    }
    return s.contains(seasonChar);
  }

  /// 与衣橱录入一致：优先精确类别，并兼容常见别名（含名称里带关键词的旧数据）
  static bool isTop(Clothing c) {
    final t = '${c.category} ${c.name}'.trim();
    if (c.category.trim() == '上衣') {
      return true;
    }
    if (c.category.contains('上衣')) {
      return true;
    }
    const keys = [
      'T恤', 't恤', '衬衫', '卫衣', '背心', '短袖', '长袖', '吊带', '针织衫',
      'Polo', 'polo', '开衫', '罩衫', '马甲', '毛衣', '西服上装',
    ];
    for (final k in keys) {
      if (t.contains(k)) {
        return true;
      }
    }
    return RegExp(
      r'\b(top|shirt|tee|t-?shirt|blouse|sweater)\b',
      caseSensitive: false,
    ).hasMatch(t);
  }

  static bool isSkirtCategory(Clothing c) {
    final cat = c.category.trim();
    return cat == '裙装' || cat.contains('裙装');
  }

  static bool isShoes(Clothing c) {
    final cat = c.category.trim();
    if (cat == '袜子' || (cat.contains('袜') && cat.length <= 3)) {
      return false;
    }
    return cat == '鞋子' || (cat.contains('鞋') && !cat.contains('裤'));
  }

  static bool isBottom(Clothing c) {
    final cat = c.category.trim();
    final t = '${c.category} ${c.name}'.trim();
    if (cat == '裙装' || cat.contains('裙装')) {
      return true;
    }
    if (cat == '下装' || cat.contains('下装')) {
      return true;
    }
    if (cat == '鞋子' ||
        cat == '配饰' ||
        cat == '包包' ||
        cat.contains('鞋') && !cat.contains('裤')) {
      return false;
    }
    if (cat.contains('内裤') || t.contains('内裤')) {
      return false;
    }
    if (cat == '袜子' || cat.contains('袜') && cat.length <= 3) {
      return false;
    }
    const keys = [
      '短裤', '长裤', '半裙', '长裙', '牛仔裤', '阔腿裤', '直筒裤', '运动裤',
      '打底裤', '短裙', '中裙', '裤裙', '西裤', '休闲裤',
    ];
    for (final k in keys) {
      if (t.contains(k)) {
        return true;
      }
    }
    if (t.contains('牛仔') && (t.contains('裤') || t.contains('裙'))) {
      return true;
    }
    if (t.contains('裤') || t.contains('裙')) {
      return true;
    }
    return RegExp(
      r'\b(pants|jeans|shorts|skirt|trousers|bottom)\b',
      caseSensitive: false,
    ).hasMatch(t);
  }

  static bool isOuter(Clothing c) => c.category.trim() == '外套' || c.category.contains('外套');

  static bool _poolHasTopAndBottom(List<Clothing> pool) {
    return pool.any(isTop) && pool.any(isBottom);
  }

  /// 可生成推荐：经典「上衣+下装」，或「裙装 + 鞋子」。
  static bool _poolHasValidRecommendation(List<Clothing> pool) {
    if (_poolHasTopAndBottom(pool)) {
      return true;
    }
    return pool.any(isSkirtCategory) && pool.any(isShoes);
  }

  /// 优先「当季 + 在穿」；若凑不齐可推荐组合（上衣+下装 / 裙装+鞋）则退回「全部在穿」
  static List<Clothing> recommendationPool(
    List<Clothing> clothes,
    String seasonChar,
  ) {
    final active =
        clothes.where((c) => c.status == _activeStatus).toList();
    final seasonal = active
        .where((c) => clothingMatchesSeason(c, seasonChar))
        .toList();
    if (_poolHasValidRecommendation(seasonal)) {
      return seasonal;
    }
    if (_poolHasValidRecommendation(active)) {
      return active;
    }
    return seasonal.isNotEmpty ? seasonal : active;
  }

  /// 最近 7 个日历日（含今天）内出现过的穿着组合（无序 `clothingIds` 集合）
  static Set<Set<String>> recentWornClothingSets(
    List<Outfit> outfits,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: 6));
    final result = <Set<String>>{};
    for (final o in outfits) {
      for (final wd in o.wornDates) {
        final l = wd.toLocal();
        final d = DateTime(l.year, l.month, l.day);
        if (d.isBefore(windowStart) || d.isAfter(today)) {
          continue;
        }
        if (o.clothingIds.isEmpty) {
          continue;
        }
        result.add(o.clothingIds.toSet());
      }
    }
    return result;
  }

  static bool sameClothingSet(Set<String> a, Set<String> b) {
    if (a.length != b.length) {
      return false;
    }
    return a.containsAll(b);
  }

  static bool conflicts(
    Set<String> candidate,
    Iterable<Set<String>> blocked,
  ) {
    for (final b in blocked) {
      if (sameClothingSet(candidate, b)) {
        return true;
      }
    }
    return false;
  }

  Future<TodayRecommendationResult> execute({
    required List<Clothing> clothes,
    required List<Outfit> outfits,
    UserProfile? profile,
    DateTime? now,
    RecommendationDayContext? dayContext,
  }) async {
    final clock = now ?? DateTime.now();
    final season = seasonForDate(clock);

    final pool = recommendationPool(clothes, season);

    final recent = recentWornClothingSets(outfits, clock);
    final blocked = <Set<String>>[...recent];

    final aiConfig = loadAiConfig();
    String? aiSkip;

    /// 与 AI 请求并行，避免电脑端配置了密钥时长时间卡在「正在生成」而规则结果其实已可展示。
    final ruleFuture = Future(
      () => _ruleBasedBundles(
        pool: pool,
        blockedAgainst: blocked,
        count: 4,
        ambientTempC: dayContext?.temperatureC,
      ),
    );

    if (aiConfig.isComplete) {
      try {
        final aiBundles = await _fetchAiRecommendations(
          config: aiConfig,
          pool: pool,
          seasonLabel: season,
          profile: profile,
          now: clock,
          dayContext: dayContext,
        ).timeout(const Duration(seconds: 14));
        if (aiBundles != null && aiBundles.length == 4) {
          return TodayRecommendationResult(
            outfits: aiBundles,
            seasonLabel: season,
            primarySource: RecommendationPrimarySource.ai,
          );
        }
        aiSkip = 'AI 返回结果无效，已使用本地规则';
      } on TimeoutException {
        aiSkip = 'AI 响应超时，已使用本地规则';
      } catch (_) {
        aiSkip = 'AI 请求失败，已使用本地规则';
      }
    } else {
      aiSkip = '未配置 AI_API_KEY / AI_API_BASE_URL，已使用本地规则';
    }

    final ruleBundles = await ruleFuture;

    return TodayRecommendationResult(
      outfits: ruleBundles,
      seasonLabel: season,
      primarySource: RecommendationPrimarySource.rule,
      aiSkippedReason: aiSkip,
    );
  }

  List<RecommendedOutfitBundle> _ruleBasedBundles({
    required List<Clothing> pool,
    required List<Set<String>> blockedAgainst,
    required int count,
    double? ambientTempC,
  }) {
    final tops = pool.where(isTop).toList();
    final bottoms = pool.where(isBottom).toList();
    final skirts = pool.where(isSkirtCategory).toList();
    final shoes = pool.where(isShoes).toList();
    final outers = pool.where(isOuter).toList();

    final canClassic = tops.isNotEmpty && bottoms.isNotEmpty;
    final canSkirtShoe = skirts.isNotEmpty && shoes.isNotEmpty;
    if (!canClassic && !canSkirtShoe) {
      return [];
    }

    final rnd = Random();
    final chosenSets = <Set<String>>[];
    final out = <RecommendedOutfitBundle>[];

    var outerChance = 0.65;
    final t = ambientTempC;
    if (t != null) {
      if (t < 8) {
        outerChance = 0.92;
      } else if (t < 16) {
        outerChance = 0.82;
      } else if (t > 30) {
        outerChance = 0.22;
      }
    }

    for (var attempt = 0; attempt < 200 && out.length < count; attempt++) {
      final ids = <String>{};
      final pickSkirtShoe = canSkirtShoe && (!canClassic || rnd.nextDouble() < 0.42);
      if (pickSkirtShoe) {
        ids.add(skirts[rnd.nextInt(skirts.length)].id);
        ids.add(shoes[rnd.nextInt(shoes.length)].id);
      } else if (canClassic) {
        final top = tops[rnd.nextInt(tops.length)];
        final bottom = bottoms[rnd.nextInt(bottoms.length)];
        ids.add(top.id);
        ids.add(bottom.id);
        if (outers.isNotEmpty && rnd.nextDouble() < outerChance) {
          ids.add(outers[rnd.nextInt(outers.length)].id);
        }
      } else {
        continue;
      }

      if (conflicts(ids, blockedAgainst) || conflicts(ids, chosenSets)) {
        continue;
      }

      final items = pool.where((c) => ids.contains(c.id)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      chosenSets.add(ids);
      out.add(
        RecommendedOutfitBundle(
          clothings: items,
          title: '今日搭配 ${out.length + 1}',
        ),
      );
    }

    return out;
  }

  Future<List<RecommendedOutfitBundle>?> _fetchAiRecommendations({
    required AiClientConfig config,
    required List<Clothing> pool,
    required String seasonLabel,
    required UserProfile? profile,
    required DateTime now,
    RecommendationDayContext? dayContext,
  }) async {
    final idSet = pool.map((e) => e.id).toSet();
    if (idSet.length < 2) {
      return null;
    }

    final wardrobeJson = pool
        .map(
          (c) => {
            'id': c.id,
            'name': c.name,
            'category': c.category,
            'season': c.season,
            'colors': c.colors,
            'style': c.style,
            'tags': c.tags,
          },
        )
        .toList();

    final profileJson = profile == null
        ? null
        : {
            'styles': profile.styles,
            'favoriteColors': profile.favoriteColors,
            'favoriteOccasions': profile.favoriteOccasions,
            'bodyType': profile.bodyType,
            'height': profile.height,
            'weight': profile.weight,
          };

    final userPrompt = jsonEncode({
      'today': '${now.year}-${now.month}-${now.day}',
      'season': seasonLabel,
      'wardrobe': wardrobeJson,
      'userProfile': profileJson,
      if (dayContext != null) 'dayContextHint': dayContext.summaryForAiPrompt,
      'rules': {
        'outfitCount': 4,
        'constraints': [
          'Each outfit must only use clothing ids from wardrobe[].id',
          'Prefer combinations with (上衣 + 下装) OR (裙装 category + 鞋子); 外套 optional when appropriate',
          'If dayContextHint is present, respect weather (layers), holiday/workday mood, and likely activities.',
          'Respond with JSON only, no markdown',
        ],
      },
    });

    final base = config.baseUrl!.replaceAll(RegExp(r'/+$'), '');
    final url = '$base/chat/completions';

    final response = await _dio.post<Map<String, dynamic>>(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 24),
      ),
      data: {
        'model': config.model,
        'temperature': 0.6,
        'messages': [
          {
            'role': 'system',
            'content': _systemPrompt,
          },
          {
            'role': 'user',
            'content': userPrompt,
          },
        ],
      },
    );

    final data = response.data;
    if (data == null) {
      return null;
    }
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      return null;
    }
    final msg = choices.first as Map<String, dynamic>?;
    final content = msg?['message']?['content'] as String?;
    if (content == null || content.isEmpty) {
      return null;
    }

    final decoded = _parseAiJson(content);
    if (decoded == null) {
      return null;
    }

    final outfitsRaw = decoded['outfits'] as List<dynamic>?;
    if (outfitsRaw == null || outfitsRaw.length < 4) {
      return null;
    }

    final byId = {for (final c in pool) c.id: c};
    final bundles = <RecommendedOutfitBundle>[];

    for (var i = 0; i < 4; i++) {
      final o = outfitsRaw[i] as Map<String, dynamic>?;
      if (o == null) {
        return null;
      }
      final title = o['title'] as String?;
      final reason = o['reason'] as String?;
      final ids = o['clothing_ids'] as List<dynamic>? ?? o['clothingIds'] as List<dynamic>?;
      if (ids == null || ids.isEmpty) {
        return null;
      }
      final idList = ids.map((e) => '$e').toList();
      final resolved = <Clothing>[];
      for (final id in idList) {
        final c = byId[id];
        if (c == null) {
          return null;
        }
        resolved.add(c);
      }
      if (!_aiOutfitIsValidCombo(resolved)) {
        return null;
      }
      bundles.add(
        RecommendedOutfitBundle(
          clothings: resolved,
          title: title ?? 'AI 推荐 ${i + 1}',
          reason: reason,
        ),
      );
    }

    return bundles;
  }

  static bool _aiOutfitIsValidCombo(List<Clothing> items) {
    if (items.any(isSkirtCategory) && items.any(isShoes)) {
      return true;
    }
    var top = false;
    var bottom = false;
    for (final c in items) {
      if (isTop(c)) {
        top = true;
      }
      if (isBottom(c)) {
        bottom = true;
      }
    }
    return top && bottom;
  }

  static Map<String, dynamic>? _parseAiJson(String raw) {
    try {
      final s = _stripMarkdownFence(raw);
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  static String _stripMarkdownFence(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      final lines = s.split('\n');
      if (lines.isNotEmpty &&
          (lines.first.contains('json') || lines.first.startsWith('```'))) {
        lines.removeAt(0);
      }
      while (lines.isNotEmpty && lines.last.trim() == '```') {
        lines.removeLast();
      }
      s = lines.join('\n').trim();
    }
    return s;
  }

  static const _systemPrompt = '''
You are a fashion assistant. Output ONE JSON object only, no markdown, no code fences.
Schema:
{"outfits":[
  {"title":"short string","reason":"one sentence","clothing_ids":["id1","id2"]},
  {"title":"...","reason":"...","clothing_ids":["..."]},
  {"title":"...","reason":"...","clothing_ids":["..."]},
  {"title":"...","reason":"...","clothing_ids":["..."]}
]}
Requirements:
- Exactly 4 objects in outfits.
- Every clothing_ids value MUST be copied from the user JSON wardrobe[].id only.
- Each outfit must be EITHER (at least one 上衣 AND one 下装/裙装 as bottom) OR (至少一件 category 裙装 AND one 鞋子).
- 外套 optional; follow dayContextHint for temperature and occasion when provided.
- Do not invent ids.
''';
}
