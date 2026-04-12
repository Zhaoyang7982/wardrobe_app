import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/clothing.dart';
import '../../../domain/models/outfit.dart';
import '../../widgets/outfit_clothing_collage.dart';

/// 搭配列表：顶部筛选、瀑布流、长按多选编辑/删除
class OutfitPage extends ConsumerStatefulWidget {
  const OutfitPage({super.key});

  @override
  ConsumerState<OutfitPage> createState() => _OutfitPageState();
}

class _OutfitPageState extends ConsumerState<OutfitPage> {
  static const _occasionFilters = ['全部', '日常', '工作', '运动', '正式', '约会', '旅行'];
  static const _seasonFilters = ['全部', '春', '夏', '秋', '冬'];

  List<Outfit> _outfits = [];
  Map<String, Clothing> _clothingById = {};
  bool _loading = true;
  String? _error;

  String _occasionFilter = '全部';
  String _seasonFilter = '全部';

  bool _selectMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _openCreateOutfit() async {
    await context.push(AppRoutePaths.outfitCreate);
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final oRepo = await ref.read(outfitRepositoryProvider.future);
      final cRepo = await ref.read(clothingRepositoryProvider.future);
      final outfits = await oRepo.getAll();
      final clothes = await cRepo.getAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _outfits = outfits;
        _clothingById = {for (final c in clothes) c.id: c};
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

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selectedIds.clear();
    });
  }

  void _onItemLongPress(String outfitId) {
    setState(() {
      _selectMode = true;
      _selectedIds.add(outfitId);
    });
  }

  void _toggleSelect(String outfitId) {
    setState(() {
      if (_selectedIds.contains(outfitId)) {
        _selectedIds.remove(outfitId);
      } else {
        _selectedIds.add(outfitId);
      }
    });
  }

  List<Outfit> get _filteredOutfits {
    return _outfits.where(_matchesFilters).toList()
      ..sort((a, b) {
        final ad = _lastWorn(a);
        final bd = _lastWorn(b);
        if (ad != null && bd != null) {
          return bd.compareTo(ad);
        }
        if (ad != null) {
          return -1;
        }
        if (bd != null) {
          return 1;
        }
        return a.name.compareTo(b.name);
      });
  }

  DateTime? _lastWorn(Outfit o) {
    if (o.wornDates.isEmpty) {
      return null;
    }
    return o.wornDates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  bool _matchesFilters(Outfit o) {
    if (_occasionFilter != '全部') {
      final occ = o.occasion;
      if (occ == null || occ.isEmpty) {
        return false;
      }
      final parts = occ.split('、').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
      if (!parts.contains(_occasionFilter) && occ != _occasionFilter) {
        return false;
      }
    }
    if (_seasonFilter != '全部') {
      final sea = o.season;
      if (sea == null || sea.isEmpty) {
        return false;
      }
      final parts = sea.split('、').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
      if (!parts.contains(_seasonFilter) && sea != _seasonFilter) {
        return false;
      }
    }
    return true;
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }
    final selected = _outfits.where((o) => _selectedIds.contains(o.id)).toList();
    if (selected.isEmpty) {
      return;
    }
    final withWear = selected.where((o) => o.wornDates.isNotEmpty).toList();
    final neverWorn = selected.where((o) => o.wornDates.isEmpty).toList();

    final String confirmBody;
    if (neverWorn.isEmpty) {
      confirmBody = withWear.length == 1
          ? '该搭配有日历「已穿」记录，移除后将进入「搭配回收站」，可在「我的」中恢复或彻底删除。'
          : '选中的 ${withWear.length} 套搭配均有已穿记录，移除后将进入「搭配回收站」。';
    } else if (withWear.isEmpty) {
      confirmBody = neverWorn.length == 1
          ? '该搭配从未在日历中标记为「已穿」。删除后将永久移除，不会进入回收站且无法恢复。'
          : '选中的 ${neverWorn.length} 套从未标记为已穿，删除后将永久移除且不会进入回收站。';
    } else {
      confirmBody =
          '已选 ${selected.length} 套：${withWear.length} 套将移入回收站，${neverWorn.length} 套将永久删除（从未标记已穿）。';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(neverWorn.isEmpty ? '移除搭配' : '永久删除搭配'),
        content: Text(confirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    try {
      final repo = await ref.read(outfitRepositoryProvider.future);
      var archived = 0;
      var purged = 0;
      for (final o in selected) {
        await repo.delete(o.id);
        if (o.wornDates.isEmpty) {
          purged++;
        } else {
          archived++;
        }
      }
      if (mounted) {
        final String msg;
        if (archived > 0 && purged > 0) {
          msg = '已移入回收站 $archived 套，已永久删除 $purged 套';
        } else if (archived > 0) {
          msg = '已移入回收站';
        } else {
          msg = '已永久删除';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        _exitSelectMode();
        await _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$e')));
      }
    }
  }

  Future<void> _editSelected() async {
    if (_selectedIds.length != 1) {
      return;
    }
    final id = _selectedIds.first;
    Outfit? outfit;
    for (final o in _outfits) {
      if (o.id == id) {
        outfit = o;
        break;
      }
    }
    if (outfit == null) {
      return;
    }

    final nameCtrl = TextEditingController(text: outfit.name);
    final notesCtrl = TextEditingController(text: outfit.notes ?? '');
    String? occasion = outfit.occasion;
    String? season = outfit.season;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              title: const Text('编辑搭配'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: '名称'),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Text('场合', style: Theme.of(context).textTheme.titleSmall),
                    Wrap(
                      spacing: AppTheme.spaceXs,
                      children: _occasionFilters
                          .where((o) => o != '全部')
                          .map((o) {
                            final sel = occasion == o;
                            return FilterChip(
                              label: Text(o),
                              selected: sel,
                              onSelected: (v) => setDialog(() => occasion = v ? o : null),
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Text('季节', style: Theme.of(context).textTheme.titleSmall),
                    Wrap(
                      spacing: AppTheme.spaceXs,
                      children: _seasonFilters
                          .where((s) => s != '全部')
                          .map((s) {
                            final sel = season == s;
                            return FilterChip(
                              label: Text(s),
                              selected: sel,
                              onSelected: (v) => setDialog(() => season = v ? s : null),
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: '备注'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
              ],
            );
          },
        );
      },
    );

    final name = nameCtrl.text.trim();
    final notesText = notesCtrl.text.trim();
    // 须在对话框子树完全卸载后再 dispose，否则 TextField 仍挂载在 Inherited 链上时会触发 framework 断言（如 _dependents.isEmpty）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameCtrl.dispose();
      notesCtrl.dispose();
    });

    if (saved != true || !mounted) {
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名称不能为空')),
      );
      return;
    }

    try {
      final repo = await ref.read(outfitRepositoryProvider.future);
      final updated = Outfit(
        id: outfit.id,
        name: name,
        clothingIds: outfit.clothingIds,
        scene: outfit.scene,
        occasion: occasion,
        season: season,
        imageUrl: outfit.imageUrl,
        wornDates: outfit.wornDates,
        plannedDates: outfit.plannedDates,
        notes: notesText.isEmpty ? null : notesText,
        isShared: outfit.isShared,
        isArchived: outfit.isArchived,
      );
      await repo.save(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
        _exitSelectMode();
        await _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredOutfits;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode ? '已选 ${_selectedIds.length} 项' : '搭配'),
        leading: _selectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectMode,
              )
            : null,
        automaticallyImplyLeading: !_selectMode,
        // 右上角 + 易被 DEBUG 横幅挡住，创建入口改为 FAB 与空状态按钮
      ),
      floatingActionButton: !_selectMode
          ? FloatingActionButton.extended(
              heroTag: 'fab_outfit',
              onPressed: _openCreateOutfit,
              icon: const Icon(Icons.add),
              label: const Text('创建搭配'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_selectMode) _FilterBar(
            occasionFilter: _occasionFilter,
            seasonFilter: _seasonFilter,
            onOccasionChanged: (v) => setState(() => _occasionFilter = v),
            onSeasonChanged: (v) => setState(() => _seasonFilter = v),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('加载失败：$_error'))
                    : filtered.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _reload,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: MediaQuery.sizeOf(context).height * 0.35,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '暂无搭配',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: theme.colorScheme.outline,
                                          ),
                                        ),
                                        const SizedBox(height: AppTheme.spaceLg),
                                        FilledButton.icon(
                                          onPressed: _openCreateOutfit,
                                          icon: const Icon(Icons.add),
                                          label: const Text('创建搭配'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final cross = AppConstants.outfitGridCrossAxisCount(constraints.maxWidth);
                              final gap = cross >= 4 ? AppTheme.spaceLg : AppTheme.spaceMd;
                              return RefreshIndicator(
                                onRefresh: _reload,
                                child: MasonryGridView.count(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppTheme.spaceMd,
                                    AppTheme.spaceSm,
                                    AppTheme.spaceMd,
                                    88,
                                  ),
                                  crossAxisCount: cross,
                                  mainAxisSpacing: gap,
                                  crossAxisSpacing: gap,
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final o = filtered[index];
                                    return _OutfitWaterfallCard(
                                      outfit: o,
                                      clothingById: _clothingById,
                                      selectMode: _selectMode,
                                      selected: _selectedIds.contains(o.id),
                                      onTap: () async {
                                        if (_selectMode) {
                                          _toggleSelect(o.id);
                                        } else {
                                          await context.push(AppRoutePaths.outfitDetail(o.id));
                                          if (mounted) {
                                            await _reload();
                                          }
                                        }
                                      },
                                      onLongPress: () => _onItemLongPress(o.id),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      bottomNavigationBar: _selectMode
          ? SafeArea(
              child: Material(
                elevation: 8,
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMd,
                    vertical: AppTheme.spaceSm,
                  ),
                  child: Row(
                    children: [
                      if (_selectedIds.length == 1)
                        TextButton.icon(
                          onPressed: _editSelected,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('编辑'),
                        ),
                      const Spacer(),
                      FilledButton.tonal(
                        onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _OutfitFilterChip extends StatelessWidget {
  const _OutfitFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: AppTheme.filterChipLabel(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.occasionFilter,
    required this.seasonFilter,
    required this.onOccasionChanged,
    required this.onSeasonChanged,
  });

  final String occasionFilter;
  final String seasonFilter;
  final ValueChanged<String> onOccasionChanged;
  final ValueChanged<String> onSeasonChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, AppTheme.spaceSm, AppTheme.spaceMd, 0),
            child: Text('场合', style: theme.textTheme.labelLarge),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              AppTheme.spaceSm,
              AppTheme.spaceMd,
              AppTheme.spaceXs,
            ),
            child: Row(
              children: [
                for (var i = 0; i < _OutfitPageState._occasionFilters.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppTheme.spaceXs),
                  _OutfitFilterChip(
                    label: _OutfitPageState._occasionFilters[i],
                    selected: occasionFilter == _OutfitPageState._occasionFilters[i],
                    onSelected: () => onOccasionChanged(_OutfitPageState._occasionFilters[i]),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, AppTheme.spaceXs, AppTheme.spaceMd, 0),
            child: Text('季节', style: theme.textTheme.labelLarge),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              AppTheme.spaceXs,
              AppTheme.spaceMd,
              AppTheme.spaceSm,
            ),
            child: Row(
              children: [
                for (var i = 0; i < _OutfitPageState._seasonFilters.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppTheme.spaceXs),
                  _OutfitFilterChip(
                    label: _OutfitPageState._seasonFilters[i],
                    selected: seasonFilter == _OutfitPageState._seasonFilters[i],
                    onSelected: () => onSeasonChanged(_OutfitPageState._seasonFilters[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitWaterfallCard extends StatelessWidget {
  const _OutfitWaterfallCard({
    required this.outfit,
    required this.clothingById,
    required this.selectMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final Outfit outfit;
  final Map<String, Clothing> clothingById;
  final bool selectMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wearCount = outfit.wornDates.length;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 4,
      surfaceTintColor: Colors.transparent,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  // 略偏「横一点」，预览区不要过高；contain 完整显示避免 cover 裁掉鞋/下摆
                  aspectRatio: 0.95,
                  child: ColoredBox(
                    color: const Color(0xFFE8E4DD),
                    child: OutfitClothingCollage(
                      clothingIds: outfit.clothingIds,
                      clothingById: clothingById,
                      compact: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.spaceSm, AppTheme.spaceSm, AppTheme.spaceSm, AppTheme.spaceXs),
                  child: Text(
                    outfit.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (outfit.occasion != null && outfit.occasion!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.spaceSm, 0, AppTheme.spaceSm, AppTheme.spaceXs),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            outfit.occasion!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.spaceSm, 0, AppTheme.spaceSm, AppTheme.spaceSm),
                  child: Text(
                    '穿着 $wearCount 次',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
            if (selectMode)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        selected ? Icons.check_circle : Icons.circle_outlined,
                        color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
