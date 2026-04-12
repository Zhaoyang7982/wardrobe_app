import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/share/load_image_bytes.dart';
import '../../core/share/outfit_share_render.dart';
import '../../core/share/share_bytes_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/stored_image_ref.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/models/clothing.dart';
import '../../domain/models/outfit.dart';
import '../widgets/outfit_clothing_collage.dart';

/// 搭配详情：封面图、名称、场合、备注、所含衣物
class OutfitDetailPage extends ConsumerStatefulWidget {
  const OutfitDetailPage({super.key, required this.outfitId});

  final String outfitId;

  @override
  ConsumerState<OutfitDetailPage> createState() => _OutfitDetailPageState();
}

class _OutfitDetailPageState extends ConsumerState<OutfitDetailPage> {
  Outfit? _outfit;
  Map<String, Clothing> _clothingById = {};
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
      final oRepo = await ref.read(outfitRepositoryProvider.future);
      final cRepo = await ref.read(clothingRepositoryProvider.future);
      final outfit = await oRepo.getById(widget.outfitId);
      if (!mounted) {
        return;
      }
      if (outfit == null) {
        setState(() {
          _outfit = null;
          _loading = false;
          _error = '未找到该搭配';
        });
        return;
      }
      final clothes = await cRepo.getAll();
      final byId = {for (final c in clothes) c.id: c};
      if (!mounted) {
        return;
      }
      setState(() {
        _outfit = outfit;
        _clothingById = byId;
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

  Future<void> _restoreToList() async {
    final o = _outfit;
    if (o == null || !o.isArchived) {
      return;
    }
    try {
      final repo = await ref.read(outfitRepositoryProvider.future);
      await repo.save(o.copyWith(isArchived: false));
      ref.invalidate(outfitRepositoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已恢复至搭配列表')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败：$e')),
        );
      }
    }
  }

  String? _coverRef(Outfit o) {
    if (o.imageUrl != null && o.imageUrl!.isNotEmpty) {
      return o.imageUrl;
    }
    for (final id in o.clothingIds) {
      final c = _clothingById[id];
      if (c == null) {
        continue;
      }
      final u = c.croppedImageUrl ?? c.imageUrl;
      if (u != null && u.isNotEmpty) {
        return u;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('搭配详情'),
        actions: [
          if (_outfit != null && _error == null && !_loading)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: '分享搭配图',
              onPressed: () => _shareOutfitImage(context),
            ),
        ],
      ),
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
              : _outfit == null
                  ? const Center(child: Text('未找到该搭配'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_outfit!.isArchived) ...[
                              Material(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppTheme.spaceSm),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        '该搭配在回收站中：已从「搭配」列表移除，日历与穿着记录仍保留。'
                                        '也可在「我的 → 搭配回收站」中恢复或彻底删除。',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                      const SizedBox(height: AppTheme.spaceSm),
                                      FilledButton.tonal(
                                        onPressed: _restoreToList,
                                        child: const Text('恢复至搭配列表'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceMd),
                            ],
                            AspectRatio(
                              aspectRatio: 1,
                              child: Material(
                                color: const Color(0xFFE8E4DD),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                clipBehavior: Clip.antiAlias,
                                child: OutfitClothingCollage(
                                  clothingIds: _outfit!.clothingIds,
                                  clothingById: _clothingById,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            Text(
                              _outfit!.name,
                              style: theme.textTheme.headlineSmall,
                            ),
                            if (_outfit!.occasion != null && _outfit!.occasion!.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spaceSm),
                              Wrap(
                                spacing: AppTheme.spaceXs,
                                children: [
                                  Chip(
                                    label: Text(_outfit!.occasion!),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                            if (_outfit!.season != null && _outfit!.season!.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spaceXs),
                              Text('季节：${_outfit!.season}', style: theme.textTheme.bodyMedium),
                            ],
                            if (_outfit!.notes != null && _outfit!.notes!.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spaceMd),
                              Text('备注', style: theme.textTheme.titleSmall),
                              const SizedBox(height: AppTheme.spaceXs),
                              Text(_outfit!.notes!, style: theme.textTheme.bodyMedium),
                            ],
                            const SizedBox(height: AppTheme.spaceLg),
                            Text('包含衣物（${_outfit!.clothingIds.length}）', style: theme.textTheme.titleSmall),
                            const SizedBox(height: AppTheme.spaceSm),
                            ..._outfit!.clothingIds.map((id) {
                              final c = _clothingById[id];
                              final refUrl = c != null ? (c.croppedImageUrl ?? c.imageUrl) : null;
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
                                  title: Text(c?.name ?? '已删除的衣物 ($id)'),
                                  subtitle: c != null ? Text(c.category) : null,
                                  trailing: c != null ? const Icon(Icons.chevron_right) : null,
                                  onTap: c != null
                                      ? () => context.push(AppRoutePaths.clothingDetail(c.id))
                                      : null,
                                ),
                              );
                            }),
                            if (_outfit!.wornDates.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: AppTheme.spaceMd),
                                child: Text(
                                  '穿着记录：${_outfit!.wornDates.length} 次',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Future<void> _shareOutfitImage(BuildContext context) async {
    final o = _outfit;
    if (o == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('正在生成分享图…'),
        duration: Duration(seconds: 30),
      ),
    );
    try {
      final refUrl = _coverRef(o);
      final raw = await loadImageRefAsBytes(refUrl);
      final png = await renderOutfitSharePng(outfitName: o.name, coverBytes: raw);
      if (!context.mounted) {
        return;
      }
      messenger.hideCurrentSnackBar();
      if (png == null) {
        messenger.showSnackBar(const SnackBar(content: Text('生成分享图失败')));
        return;
      }
      final safe = o.name.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
      await shareFileBytes(
        bytes: png,
        fileName: '搭配_$safe.png',
        mimeType: 'image/png',
      );
    } catch (e) {
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text('分享失败：$e')));
      }
    }
  }

}
