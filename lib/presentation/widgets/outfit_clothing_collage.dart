import 'package:flutter/material.dart';

import '../../core/utils/stored_image_ref.dart';
import '../../domain/models/clothing.dart';

/// 按搭配内衣物 id 顺序拼贴缩略图（与搭配详情顶栏规则一致）。
///
/// [compact] 为 true 时用于列表小卡，占位图标略小。
class OutfitClothingCollage extends StatelessWidget {
  const OutfitClothingCollage({
    super.key,
    required this.clothingIds,
    required this.clothingById,
    this.compact = false,
  });

  final List<String> clothingIds;
  final Map<String, Clothing> clothingById;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainIcon = compact ? 36.0 : 56.0;
    final cellIcon = compact ? 22.0 : 32.0;

    final ph = Center(
      child: Icon(Icons.style_outlined, size: mainIcon, color: theme.colorScheme.outline),
    );
    if (clothingIds.isEmpty) {
      return ph;
    }

    final refs = clothingIds
        .map((id) {
          final c = clothingById[id];
          return c != null ? (c.croppedImageUrl ?? c.imageUrl) : null;
        })
        .toList();

    Widget cell(String? refUrl) {
      final inner = refUrl == null || refUrl.isEmpty
          ? Center(
              child: Icon(
                Icons.checkroom_outlined,
                size: cellIcon,
                color: theme.colorScheme.outline.withValues(alpha: 0.65),
              ),
            )
          : imageFromClothingRef(
              refUrl,
              fit: BoxFit.contain,
              imageAlignment: Alignment.center,
              placeholder: const SizedBox.expand(),
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.outline),
              ),
            );
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.14),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: inner,
        ),
      );
    }

    final n = refs.length;
    if (n == 1) {
      return cell(refs[0]);
    }
    if (n == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cell(refs[0])),
          const SizedBox(width: 4),
          Expanded(child: cell(refs[1])),
        ],
      );
    }
    if (n == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cell(refs[0])),
                const SizedBox(width: 4),
                Expanded(child: cell(refs[1])),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: cell(refs[2])),
        ],
      );
    }
    if (n == 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cell(refs[0])),
                const SizedBox(width: 4),
                Expanded(child: cell(refs[1])),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cell(refs[2])),
                const SizedBox(width: 4),
                Expanded(child: cell(refs[3])),
              ],
            ),
          ),
        ],
      );
    }

    const gap = 4.0;
    final cols = n <= 6 ? 3 : 4;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final w = (maxW - gap * (cols - 1)) / cols;
        final rows = (n + cols - 1) ~/ cols;
        final h = (maxH - gap * (rows - 1)) / rows;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < n; i++)
              SizedBox(
                width: w,
                height: h,
                child: cell(refs[i]),
              ),
          ],
        );
      },
    );
  }
}
