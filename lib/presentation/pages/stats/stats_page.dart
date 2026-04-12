import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/utils/wardrobe_stats.dart';

/// 衣橱统计：概览、饼图、柱状图、排行与消费
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  /// 柔和、色相分散的色环（与粉/玫瑰衣橱主题协调）
  static const _donutHueDegrees = <double>[
    352, 310, 268, 220, 175, 135, 42, 18,
  ];

  WardrobeStatsSnapshot? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cRepo = await ref.read(clothingRepositoryProvider.future);
      final oRepo = await ref.read(outfitRepositoryProvider.future);
      final clothes = await cRepo.getAll();
      final outfits = await oRepo.getAllIncludingArchived();
      if (!mounted) {
        return;
      }
      setState(() {
        _stats = WardrobeStatsSnapshot.compute(clothes, outfits, DateTime.now());
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 0);
    final currency2 = NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('统计分析')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: AppTheme.spaceMd),
                        FilledButton(onPressed: _load, child: const Text('重试')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    children: [
                      if (_stats != null) ..._buildSections(theme, currency, currency2),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildSections(
    ThemeData theme,
    NumberFormat currency,
    NumberFormat currency2,
  ) {
    final s = _stats!;
    return [
      _sectionTitle(theme, '衣橱概览'),
      const SizedBox(height: AppTheme.spaceSm),
      _overviewRow(theme, s, currency),
      const SizedBox(height: AppTheme.spaceLg),
      _sectionTitle(theme, '类别分布'),
      const SizedBox(height: AppTheme.spaceSm),
      _categoryPie(theme, s),
      const SizedBox(height: AppTheme.spaceLg),
      _sectionTitle(theme, '利用率排行'),
      const SizedBox(height: AppTheme.spaceSm),
      _top10Wear(theme, s),
      const SizedBox(height: AppTheme.spaceMd),
      _sectionTitle(theme, '尚未记入「日历已穿」的衣物', subtitle: '共 ${s.neverWorn.length} 件'),
      Text(
        '说明：只有当你在「日历」里把某套搭配标记为「已穿」时，该套里的单品才会算作「穿过」。'
        '下列是至今还从未出现在任何一次「已穿」记录里的衣服。',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
      ),
      const SizedBox(height: AppTheme.spaceSm),
      _neverWornList(theme, s),
      const SizedBox(height: AppTheme.spaceLg),
      _sectionTitle(theme, '消费分析'),
      const SizedBox(height: AppTheme.spaceSm),
      _spendByCategory(theme, s, currency),
      const SizedBox(height: AppTheme.spaceMd),
      _sectionTitle(theme, '每次穿着成本', subtitle: '购买价 ÷ 日历已穿次数'),
      const SizedBox(height: AppTheme.spaceSm),
      _costPerWear(theme, s, currency2),
      const SizedBox(height: 48),
    ];
  }

  Widget _sectionTitle(ThemeData theme, String title, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ],
      ],
    );
  }

  Widget _overviewRow(ThemeData theme, WardrobeStatsSnapshot s, NumberFormat currency) {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            label: '总件数',
            value: '${s.totalPieces}',
            icon: Icons.checkroom_outlined,
            theme: theme,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: _OverviewCard(
            label: '总价值',
            value: s.pricedPieces == 0 ? '—' : currency.format(s.totalValue),
            icon: Icons.payments_outlined,
            theme: theme,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: _OverviewCard(
            label: '本月穿着',
            value: '${s.monthlyWearSessions}',
            icon: Icons.event_available_outlined,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Color _donutSliceBase(ThemeData theme, int index) {
    final h = _donutHueDegrees[index % _donutHueDegrees.length];
    final isDark = theme.brightness == Brightness.dark;
    return HSLColor.fromAHSL(1, h, isDark ? 0.38 : 0.34, isDark ? 0.55 : 0.87).toColor();
  }

  Gradient _donutSliceGradient(Color base) {
    final hsl = HSLColor.fromColor(base);
    final hi = hsl.withLightness((hsl.lightness + 0.07).clamp(0.5, 0.96)).toColor();
    final lo = hsl.withLightness((hsl.lightness - 0.08).clamp(0.35, 0.9)).toColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [hi, base, lo],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  Widget _categoryPie(ThemeData theme, WardrobeStatsSnapshot s) {
    final entries = s.categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return const Text('暂无数据');
    }
    final total = entries.fold<int>(0, (a, e) => a + e.value);
    final gapColor = theme.colorScheme.surface;
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final base = _donutSliceBase(theme, i);
      sections.add(
        PieChartSectionData(
          color: base,
          gradient: _donutSliceGradient(base),
          value: e.value.toDouble(),
          radius: 64,
          showTitle: false,
          borderSide: BorderSide(color: gapColor, width: 3),
        ),
      );
    }

    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 3.2,
                      centerSpaceRadius: 56,
                      centerSpaceColor: gapColor,
                      startDegreeOffset: -90,
                    ),
                  ),
                  IgnorePointer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          '件衣物',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: List.generate(entries.length, (i) {
                final e = entries[i];
                final pct = total == 0 ? 0.0 : e.value / total * 100;
                final dot = _donutSliceBase(theme, i);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        gradient: _donutSliceGradient(dot),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dot.withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${e.key} · ${e.value}件 · ${pct.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// 利用率条填充：比旧版略深，与浅色轨道对比更清晰（仍沿用主色色相）
  Color _wearRankBarFill(ThemeData theme) {
    final p = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final hsl = HSLColor.fromColor(p);
    return hsl
        .withSaturation((hsl.saturation * 0.62).clamp(0.22, 0.52))
        .withLightness(isDark ? 0.52 : 0.62)
        .toColor();
  }

  Color _wearRankBarTrack(ThemeData theme) {
    final cs = theme.colorScheme;
    return Color.alphaBlend(
      cs.outline.withValues(alpha: 0.18),
      cs.surfaceContainerHighest,
    );
  }

  Widget _top10Wear(ThemeData theme, WardrobeStatsSnapshot s) {
    final list = s.top10ByWear;
    if (list.isEmpty) {
      return Text(
        '暂无日历「已穿」记录：在日历中为搭配标记已穿后，这里会显示排行。',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
      );
    }
    final maxC = list.map(s.outfitWearSessions).reduce(math.max).clamp(1, 999999);
    final barFill = _wearRankBarFill(theme);
    final barTrack = _wearRankBarTrack(theme);
    const barRadius = 999.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          children: list.asMap().entries.map((e) {
            final c = e.value;
            final rank = e.key + 1;
            final wears = s.outfitWearSessions(c);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '$rank',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$wears 次',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(barRadius),
                    child: LinearProgressIndicator(
                      value: wears / maxC,
                      minHeight: 10,
                      color: barFill,
                      backgroundColor: barTrack,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _neverWornList(ThemeData theme, WardrobeStatsSnapshot s) {
    if (s.neverWorn.isEmpty) {
      return Text(
        '当前没有这类衣物：衣橱里每一件都至少出现在过一次「日历 → 已穿」里。',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
      );
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: s.neverWorn.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final c = s.neverWorn[i];
          return ListTile(
            dense: true,
            title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(c.category),
            trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
            onTap: () async {
              await context.push(AppRoutePaths.clothingDetail(c.id));
              if (mounted) {
                await _load();
              }
            },
          );
        },
      ),
    );
  }

  Widget _spendByCategory(ThemeData theme, WardrobeStatsSnapshot s, NumberFormat currency) {
    if (s.spendByCategory.isEmpty) {
      return Text('暂无标价数据', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline));
    }
    final entries = s.spendByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          children: entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(e.key)),
                      Text(currency.format(e.value)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value / maxV,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _costPerWear(ThemeData theme, WardrobeStatsSnapshot s, NumberFormat currency2) {
    final list = s.clothesForCostPerWear;
    if (list.isEmpty) {
      return Text(
        '需要有购买价，且在日历「已穿」中累计至少 1 次的衣物',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
      );
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final c = list[i];
          final wears = s.outfitWearSessions(c);
          final cpu = c.purchasePrice! / wears;
          return ListTile(
            dense: true,
            title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${c.category} · 日历已穿 $wears 次 · 购入 ${currency2.format(c.purchasePrice!)}'),
            trailing: Text(
              currency2.format(cpu),
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
  });

  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
