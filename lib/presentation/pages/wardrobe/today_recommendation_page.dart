import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/today_recommendation_provider.dart';
import '../../widgets/today_recommendation_section.dart';

/// 衣橱二级页：展示今日智能推荐（与衣橱首页解耦，避免占用网格区域）
class TodayRecommendationPage extends ConsumerWidget {
  const TodayRecommendationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日推荐')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayRecommendationProvider);
          await ref.read(todayRecommendationProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: TodayRecommendationSection(
                compactMargins: true,
                useMasonryGrid: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
