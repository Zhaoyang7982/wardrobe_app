import 'package:intl/intl.dart';

/// 用于「今日推荐」展示的日期、工作日/节假日与天气摘要（由 [RecommendationDayContextLoader] 填充）。
class RecommendationDayContext {
  /// 与数据层约定：来自系统最近已知位置的原始提示文案（[locationHintForUi] 会据此改写展示）。
  static const lastKnownBackendHint = '最近位置（系统缓存，略旧）';

  const RecommendationDayContext({
    required this.localDate,
    required this.longDateLabel,
    required this.weekdayLabel,
    required this.isWeekend,
    required this.isWorkdayFromApi,
    this.holidayName,
    this.temperatureC,
    this.weatherDescription,
    this.locationHint,
    this.locationFromLastKnown = false,
    this.locationFixTime,
    this.holidayApiFailed = false,
    this.weatherApiFailed = false,
    this.webWeatherSuppressed = false,
  });

  final DateTime localDate;
  final String longDateLabel;
  final String weekdayLabel;
  final bool isWeekend;

  /// timor.tech：0 工作日 1 周末 2 节假日（解析失败时与 [isWeekend] 组合推断）
  final bool isWorkdayFromApi;
  final String? holidayName;
  final double? temperatureC;
  final String? weatherDescription;
  final String? locationHint;

  /// 为 true 时表示坐标来自系统「最近已知位置」缓存（非本次实时 GPS）。
  final bool locationFromLastKnown;

  /// 与 [locationFromLastKnown] 配套的缓存定位时间（可能为 null）。
  final DateTime? locationFixTime;
  final bool holidayApiFailed;
  final bool weatherApiFailed;

  /// Web 端规则推荐：不请求天气接口，避免展示「默认北京」等与「本地规则」语义冲突。
  final bool webWeatherSuppressed;

  /// 列表与引导语用：在「缓存点 + 天气已成功」且时效可接受时改为「当前区域」，不提缓存。
  String? get locationHintForUi {
    final h = locationHint;
    if (h == null || h.isEmpty) {
      return h;
    }
    if (!locationFromLastKnown || h != lastKnownBackendHint) {
      return h;
    }
    if (weatherApiFailed || temperatureC == null || weatherDescription == null) {
      return h;
    }
    final t = locationFixTime;
    if (t == null) {
      return '当前区域';
    }
    final age = DateTime.now().difference(t);
    if (age <= const Duration(hours: 48) && !age.isNegative) {
      return '当前区域';
    }
    return h;
  }

  /// 供 AI user JSON 附加的一行摘要
  String get summaryForAiPrompt {
    final w = temperatureC != null && weatherDescription != null
        ? '${temperatureC!.round()}°C $weatherDescription'
        : (weatherDescription ?? '天气未知');
    final h = holidayName ?? '无额外节假日名';
    final dayKind = isWeekend ? '周末' : (isWorkdayFromApi ? '工作日' : '休息日');
    final loc = locationHint ?? '未知'; // AI 侧保留原始来源说明
    return 'context: date=$longDateLabel $weekdayLabel; $dayKind; holiday=$h; weather=$w; location=$loc';
  }

  /// 人性化说明（展示在推荐列表下方）
  String buildFriendlyIntro({required int outfitCount}) {
    final parts = <String>[];
    parts.add('今天是 $longDateLabel，$weekdayLabel。${_calendarSituationLine()}');
    if (temperatureC != null && weatherDescription != null) {
      final uiLoc = locationHintForUi;
      parts.add(
        '${uiLoc != null && uiLoc.isNotEmpty ? '「$uiLoc」' : ''}当前约 ${temperatureC!.round()}°C，$weatherDescription。',
      );
    } else if (weatherApiFailed) {
      parts.add(
        '暂时无法获取实时天气（可检查网络，或在系统设置中为本应用开启大致定位权限后重试）。',
      );
    } else {
      parts.add('今日天气信息暂不可用。');
    }
    if (holidayApiFailed) {
      parts.add('节假日数据暂未能联网校验，已按周末/工作日作简单参考。');
    }
    parts.add(
      '结合以上情况，我为你准备了 $outfitCount 套搭配思路，方便你快速出门或换换心情；若不满意，可以多滑几套试试～',
    );
    return parts.join('\n');
  }

  /// Web 端规则推荐用：简短中性说明，避免长段助手口吻（与 [buildFriendlyIntro] 二选一）。
  String buildWebRuleIntro({required int outfitCount}) {
    final parts = <String>[];
    parts.add('$longDateLabel · $weekdayLabel。${_calendarSituationLine()}');
    if (webWeatherSuppressed) {
      parts.add('Web 端不请求定位与天气，推荐仅依据衣橱「在穿」与本地规则。');
    } else if (temperatureC != null && weatherDescription != null) {
      final uiLoc = locationHintForUi;
      parts.add(
        '${uiLoc != null && uiLoc.isNotEmpty ? '「$uiLoc」' : ''}约 ${temperatureC!.round()}°C，$weatherDescription。',
      );
    } else if (weatherApiFailed) {
      parts.add('天气信息暂不可用。');
    } else {
      parts.add('今日天气信息暂不可用。');
    }
    parts.add('已从衣橱「在穿」中按本地规则组合 $outfitCount 套搭配，点击卡片可查看所含衣物。');
    return parts.join('\n');
  }

  String _calendarSituationLine() {
    final name = holidayName?.trim();
    if (name != null && name.isNotEmpty && name.contains('补班')) {
      return '今天是调休补班（$name），通勤与室内外温差更值得纳入搭配考量。';
    }
    if (name != null && name.isNotEmpty) {
      return '今天是法定节假日或休息日：$name。';
    }
    if (isWeekend) {
      return '今天是周末，更适合休闲、约会或短途出行。';
    }
    return '今天是工作日，通勤与室内外温差也值得纳入搭配考量。';
  }

  /// 无网络时的最小上下文（仍生成可读日期与引导语）
  static RecommendationDayContext localFallback(DateTime now) {
    final l = now.toLocal();
    final long = DateFormat('y年M月d日', 'zh_CN').format(l);
    final wd = DateFormat('EEEE', 'zh_CN').format(l);
    final weekend = l.weekday == DateTime.saturday || l.weekday == DateTime.sunday;
    return RecommendationDayContext(
      localDate: l,
      longDateLabel: long,
      weekdayLabel: wd,
      isWeekend: weekend,
      isWorkdayFromApi: !weekend,
      holidayApiFailed: true,
      weatherApiFailed: true,
    );
  }
}
