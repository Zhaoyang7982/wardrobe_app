import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/stored_image_ref.dart';
import '../../../domain/usecases/outfit_recommendation_usecase.dart';
import '../../widgets/outfit_clothing_collage.dart';

/// 今日推荐等「未落库搭配」的详情：布局接近 [OutfitDetailPage]，无穿着记录与分享。
class RecommendedOutfitDetailPage extends StatelessWidget {
  const RecommendedOutfitDetailPage({super.key, required this.bundle});

  final RecommendedOutfitBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = bundle.title ?? '推荐搭配';
    final clothingIds = bundle.clothings.map((c) => c.id).toList();
    final clothingById = {for (final c in bundle.clothings) c.id: c};

    return Scaffold(
      appBar: AppBar(title: const Text('推荐搭配')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Material(
                color: const Color(0xFFE8E4DD),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceSm),
                  child: OutfitClothingCollage(
                    clothingIds: clothingIds,
                    clothingById: clothingById,
                    compact: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(title, style: theme.textTheme.headlineSmall),
            if (bundle.reason != null && bundle.reason!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Text(bundle.reason!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: AppTheme.spaceLg),
            Text('包含衣物（${bundle.clothings.length}）', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceSm),
            ...bundle.clothings.map((c) {
              final refUrl = c.croppedImageUrl ?? c.imageUrl;
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: ListTile(
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: refUrl != null && refUrl.isNotEmpty
                          ? imageFromClothingRef(
                              refUrl,
                              fit: BoxFit.cover,
                              placeholder: Icon(Icons.checkroom_outlined, color: theme.colorScheme.outline),
                              errorBuilder: (ctx, e, s) =>
                                  Icon(Icons.checkroom_outlined, color: theme.colorScheme.outline),
                            )
                          : Icon(Icons.checkroom_outlined, color: theme.colorScheme.outline),
                    ),
                  ),
                  title: Text(c.name),
                  subtitle: Text(c.category),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutePaths.clothingDetail(c.id)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
