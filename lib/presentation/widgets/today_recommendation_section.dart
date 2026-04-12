import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/models/outfit.dart';
import '../../domain/models/recommendation_day_context.dart';
import '../../domain/usecases/outfit_recommendation_usecase.dart';
import '../providers/today_recommendation_provider.dart';
import 'outfit_clothing_collage.dart';

/// 今日推荐内容块（规则离线可用；可选 AI）。
///
/// [compactMargins] 为 true 时用于独立页，由外层 [Padding] 控制水平边距。
///
/// [useMasonryGrid] 为 true 时使用与「搭配」页一致的双列瀑布流纵向排布。
class TodayRecommendationSection extends ConsumerWidget {
  const TodayRecommendationSection({
    super.key,
    this.compactMargins = false,
    this.useMasonryGrid = false,
  });

  final bool compactMargins;
  final bool useMasonryGrid;

  EdgeInsets get _cardMargin => compactMargins
      ? EdgeInsets.zero
      : const EdgeInsets.fromLTRB(
          AppTheme.spaceMd,
          0,
          AppTheme.spaceMd,
          AppTheme.spaceSm,
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayRecommendationProvider);
    final theme = Theme.of(context);

    return async.when(
      data: (result) => _TodayRecommendationCard(
        result: result,
        margin: _cardMargin,
        useMasonryGrid: useMasonryGrid,
      ),
      loading: () => Card(
        margin: _cardMargin,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Text(
                  '正在结合今日日期、节假日与天气生成推荐…',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Card(
        margin: _cardMargin,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Text(
            '今日推荐加载失败：$e',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayRecommendationCard extends StatelessWidget {
  const _TodayRecommendationCard({
    required this.result,
    required this.margin,
    required this.useMasonryGrid,
  });

  final TodayRecommendationResult result;
  final EdgeInsets margin;
  final bool useMasonryGrid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceLabel = result.primarySource == RecommendationPrimarySource.ai
        ? 'AI 推荐'
        : '智能搭配';

    return Card(
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '今日推荐',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${result.seasonLabel}季 · $sourceLabel',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            if (result.dayContext != null) ...[
              const SizedBox(height: AppTheme.spaceSm),
              _DayContextSummaryRow(ctx: result.dayContext!),
            ],
            const SizedBox(height: AppTheme.spaceSm),
            if (result.outfits.isEmpty)
              Text(
                '暂无可推荐搭配：请至少有一件上装类、一件下装类衣物，状态为「在穿」。'
                '若已添加仍不显示，请检查类别是否为上衣/T 恤/衬衫等，以及短裤/长裤等；'
                '季节与当前月份不一致时，会自动用全部「在穿」衣物再试。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else if (useMasonryGrid)
              MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppTheme.spaceMd,
                crossAxisSpacing: AppTheme.spaceMd,
                itemCount: result.outfits.length,
                itemBuilder: (context, i) {
                  return RecommendedOutfitBundleTile(bundle: result.outfits[i]);
                },
              )
            else
              SizedBox(
                height: 248,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: result.outfits.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppTheme.spaceSm),
                  itemBuilder: (context, i) {
                    return SizedBox(
                      width: 172,
                      child: RecommendedOutfitBundleTile(bundle: result.outfits[i]),
                    );
                  },
                ),
              ),
            if (result.dayContext != null && result.outfits.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceMd),
              Text(
                result.dayContext!.buildFriendlyIntro(
                  outfitCount: result.outfits.length,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.45,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayContextSummaryRow extends StatelessWidget {
  const _DayContextSummaryRow({required this.ctx});

  final RecommendationDayContext ctx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workLabel = ctx.isWorkdayFromApi ? '工作日' : '休息日';
    final weatherBits = <String>[];
    if (ctx.temperatureC != null && ctx.weatherDescription != null) {
      weatherBits.add('约 ${ctx.temperatureC!.round()}°C · ${ctx.weatherDescription}');
    } else if (ctx.weatherApiFailed) {
      weatherBits.add('天气暂不可用');
    }
    final locUi = ctx.locationHintForUi;
    if (locUi != null && locUi.isNotEmpty) {
      weatherBits.add(locUi);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${ctx.longDateLabel} · ${ctx.weekdayLabel}',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _SoftChip(theme: theme, label: workLabel),
            if (ctx.holidayName != null && ctx.holidayName!.isNotEmpty)
              _SoftChip(theme: theme, label: ctx.holidayName!),
            if (ctx.isWeekend) _SoftChip(theme: theme, label: '周末'),
            if (weatherBits.isNotEmpty)
              _SoftChip(theme: theme, label: weatherBits.join(' · ')),
          ],
        ),
      ],
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.theme, required this.label});

  final ThemeData theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}

/// 单套推荐搭配卡片（拼贴预览 + 标题），可用于横向列表或双列网格。
class RecommendedOutfitBundleTile extends ConsumerWidget {
  const RecommendedOutfitBundleTile({super.key, required this.bundle});

  final RecommendedOutfitBundle bundle;

  static bool _sameClothingSet(Outfit o, Set<String> ids) {
    if (o.clothingIds.length != ids.length) {
      return false;
    }
    return o.clothingIds.every(ids.contains);
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final ids = bundle.clothings.map((c) => c.id).toSet();
    try {
      final repo = await ref.read(outfitRepositoryProvider.future);
      final outfits = await repo.getAll();
      for (final o in outfits) {
        if (_sameClothingSet(o, ids)) {
          if (context.mounted) {
            context.push(AppRoutePaths.outfitDetail(o.id));
          }
          return;
        }
      }
    } catch (_) {
      // 忽略，走推荐预览页
    }
    if (context.mounted) {
      context.push(AppRoutePaths.recommendedOutfitPreview, extra: bundle);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final title = bundle.title ?? '推荐搭配';
    final clothingIds = bundle.clothings.map((c) => c.id).toList();
    final clothingById = {for (final c in bundle.clothings) c.id: c};

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0.5,
      shadowColor: theme.shadowColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onTap(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 0.95,
              child: ColoredBox(
                color: const Color(0xFFE8E4DD),
                child: OutfitClothingCollage(
                  clothingIds: clothingIds,
                  clothingById: clothingById,
                  compact: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceSm,
                AppTheme.spaceSm,
                AppTheme.spaceSm,
                AppTheme.spaceXs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (bundle.reason != null && bundle.reason!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      bundle.reason!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
