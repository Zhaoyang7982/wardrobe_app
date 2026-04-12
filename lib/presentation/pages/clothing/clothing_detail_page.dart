import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/stored_image_ref.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/clothing.dart';
import '../../../domain/models/outfit.dart';

/// 衣物详情：大图切换、信息卡片、标签、穿着记录、相关搭配、编辑/删除。
/// Web 宽屏（≥900）为左图右文，操作按钮在右侧栏底部右对齐。
class ClothingDetailPage extends ConsumerStatefulWidget {
  const ClothingDetailPage({super.key, required this.clothingId});

  final String clothingId;

  @override
  ConsumerState<ClothingDetailPage> createState() => _ClothingDetailPageState();
}

class _ClothingDetailPageState extends ConsumerState<ClothingDetailPage> {
  Future<_ClothingDetailData>? _future;
  bool _showCutout = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _future = _load();
      });
    });
  }

  Future<_ClothingDetailData> _load() async {
    final cRepo = await ref.read(clothingRepositoryProvider.future);
    final oRepo = await ref.read(outfitRepositoryProvider.future);
    final clothing = await cRepo.getById(widget.clothingId);
    final outfits = await oRepo.listContainingClothing(widget.clothingId);
    return _ClothingDetailData(clothing: clothing, outfits: outfits);
  }

  String? _nonEmptyRef(String? u) {
    if (u == null || u.trim().isEmpty) {
      return null;
    }
    return u;
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _onDelete(Clothing clothing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除衣物'),
        content: Text('确定删除「${clothing.name}」？此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _deleting = true);
    try {
      final repo = await ref.read(clothingRepositoryProvider.future);
      await repo.delete(clothing.id);
      if (mounted) {
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _onEdit(Clothing c) async {
    await context.push(AppRoutePaths.clothingEdit(c.id));
    if (mounted) {
      setState(() => _future = _load());
    }
  }

  bool _useWebWideUi(BuildContext context) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= AppConstants.layoutDesktopMinWidth;
  }

  Widget _buildImagePanel(
    ThemeData theme,
    Clothing c,
    String? displayRef,
    bool hasCut,
    bool hasOrig,
  ) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: displayRef != null
                    ? imageFromClothingRef(
                        displayRef,
                        fit: BoxFit.contain,
                        placeholder: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                      ),
              ),
              if (hasCut && hasOrig)
                Positioned(
                  left: AppTheme.spaceMd,
                  right: AppTheme.spaceMd,
                  bottom: AppTheme.spaceMd,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('抠图'),
                        icon: Icon(Icons.crop_free, size: 18),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('原图'),
                        icon: Icon(Icons.photo_outlined, size: 18),
                      ),
                    ],
                    selected: {_showCutout},
                    onSelectionChanged: (s) {
                      if (s.isEmpty) {
                        return;
                      }
                      setState(() => _showCutout = s.first);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSections(ThemeData theme, Clothing c, _ClothingDetailData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: '基本信息',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('名称', c.name),
              _InfoRow('类别', c.category),
              if (c.brand != null && c.brand!.isNotEmpty) _InfoRow('品牌', c.brand!),
              if (c.size != null && c.size!.isNotEmpty) _InfoRow('尺码', c.size!),
              _InfoRow('状态', c.status),
              if (c.purchaseDate != null) _InfoRow('购入日期', _formatDate(c.purchaseDate!)),
              if (c.purchasePrice != null) _InfoRow('购入价格', '¥${c.purchasePrice!.toStringAsFixed(2)}'),
              if (c.notes != null && c.notes!.isNotEmpty) _InfoRow('备注', c.notes!),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        _SectionCard(
          title: '标签',
          child: _TagChips(clothing: c),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        _SectionCard(
          title: '穿着记录',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                '最近穿着',
                c.lastWornDate != null ? _formatDate(c.lastWornDate!) : '尚未记录',
              ),
              _InfoRow('总穿着次数', '${c.usageCount} 次'),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        _SectionCard(
          title: '包含此衣物的搭配',
          child: data.outfits.isEmpty
              ? Text(
                  '暂无搭配',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                )
              : Column(
                  children: data.outfits
                      .map(
                        (o) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(o.name),
                          subtitle: o.scene != null && o.scene!.isNotEmpty ? Text(o.scene!) : null,
                          trailing: Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.outline,
                          ),
                          onTap: () => context.push(AppRoutePaths.outfitDetail(o.id)),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildActionBar(ThemeData theme, Clothing c, {required bool webWide}) {
    final deleteChild = _deleting
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Text('删除');

    if (webWide) {
      return Material(
        elevation: 8,
        color: theme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              AppTheme.spaceSm,
              AppTheme.spaceMd,
              AppTheme.spaceMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _deleting ? null : () => _onDelete(c),
                  child: deleteChild,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                FilledButton(
                  onPressed: _deleting ? null : () => _onEdit(c),
                  child: const Text('编辑'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceSm,
            AppTheme.spaceMd,
            AppTheme.spaceMd,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _deleting ? null : () => _onDelete(c),
                  child: deleteChild,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: FilledButton(
                  onPressed: _deleting ? null : () => _onEdit(c),
                  child: const Text('编辑'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<_ClothingDetailData>(
      future: _future,
      builder: (context, snapshot) {
        if (_future == null || snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('衣物详情')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('衣物详情')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: Text('加载失败：${snapshot.error}', textAlign: TextAlign.center),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final c = data.clothing;
        if (c == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('衣物详情')),
            body: const Center(child: Text('未找到该衣物')),
          );
        }

        final cutRef = _nonEmptyRef(c.croppedImageUrl);
        final origRef = _nonEmptyRef(c.imageUrl);
        final hasCut = cutRef != null;
        final hasOrig = origRef != null;
        final displayRef = _showCutout && hasCut
            ? cutRef
            : (hasOrig ? origRef : cutRef);

        final webWide = _useWebWideUi(context);

        if (webWide) {
          return Scaffold(
            appBar: AppBar(title: Text(c.name)),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildImagePanel(theme, c, displayRef, hasCut, hasOrig),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            setState(() => _future = _load());
                            await _future;
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.spaceMd,
                              AppTheme.spaceMd,
                              AppTheme.spaceMd,
                              AppTheme.spaceLg,
                            ),
                            child: _buildDetailSections(theme, c, data),
                          ),
                        ),
                      ),
                      _buildActionBar(theme, c, webWide: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(c.name)),
          body: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _future = _load());
                    await _future;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImagePanel(theme, c, displayRef, hasCut, hasOrig),
                        Padding(
                          padding: const EdgeInsets.all(AppTheme.spaceMd),
                          child: _buildDetailSections(theme, c, data),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildActionBar(theme, c, webWide: false),
            ],
          ),
        );
      },
    );
  }
}

class _ClothingDetailData {
  const _ClothingDetailData({required this.clothing, required this.outfits});

  final Clothing? clothing;
  final List<Outfit> outfits;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _TagChips extends StatelessWidget {
  const _TagChips({required this.clothing});

  final Clothing clothing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];

    void addLabel(String label, String text) {
      chips.add(
        Chip(
          label: Text('$label：$text'),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    for (final color in clothing.colors) {
      if (color.isNotEmpty) {
        addLabel('颜色', color);
      }
    }
    for (final t in clothing.tags) {
      if (t.isNotEmpty) {
        chips.add(
          Chip(
            label: Text(t),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      }
    }
    if (clothing.season != null && clothing.season!.isNotEmpty) {
      addLabel('季节', clothing.season!);
    }
    if (clothing.occasion != null && clothing.occasion!.isNotEmpty) {
      addLabel('场合', clothing.occasion!);
    }
    if (clothing.style != null && clothing.style!.isNotEmpty) {
      addLabel('风格', clothing.style!);
    }

    if (chips.isEmpty) {
      return Text(
        '暂无标签',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
        ),
      );
    }

    return Wrap(
      spacing: AppTheme.spaceXs,
      runSpacing: AppTheme.spaceXs,
      children: chips,
    );
  }
}
