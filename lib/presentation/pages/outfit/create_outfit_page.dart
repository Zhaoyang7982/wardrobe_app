import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/stored_image_ref.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/clothing.dart';
import '../../../domain/models/outfit.dart';
import '../../widgets/outfit_clothing_collage.dart';

/// 创建搭配：上为拼贴预览 + 已选列表（可排序/移除），下为分类选择器
class CreateOutfitPage extends ConsumerStatefulWidget {
  const CreateOutfitPage({super.key});

  @override
  ConsumerState<CreateOutfitPage> createState() => _CreateOutfitPageState();
}

class _CreateOutfitPageState extends ConsumerState<CreateOutfitPage> {
  static const _categories = ['全部', '上衣', '下装', '裙装', '外套', '鞋子', '配饰', '包包'];
  static const _occasions = ['日常', '工作', '运动', '正式', '约会', '旅行'];

  final _uuid = const Uuid();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  String _tabCategory = '全部';
  List<Clothing> _allClothes = [];
  bool _loading = true;
  String? _loadError;

  /// 已加入本套搭配的衣物（顺序即拼贴与保存顺序）
  final List<Clothing> _selectedClothing = [];

  String? _saveOccasion;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadClothes());
  }

  Future<void> _loadClothes() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final repo = await ref.read(clothingRepositoryProvider.future);
      final list = await repo.getAll();
      if (mounted) {
        setState(() {
          _allClothes = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = '$e';
          _loading = false;
        });
      }
    }
  }

  List<Clothing> get _filteredClothes {
    if (_tabCategory == '全部') {
      return _allClothes;
    }
    return _allClothes.where((c) => c.category == _tabCategory).toList();
  }

  String? _cutoutRef(Clothing c) => c.croppedImageUrl ?? c.imageUrl;

  Set<String> get _selectedIds => _selectedClothing.map((e) => e.id).toSet();

  Map<String, Clothing> get _clothingById => {for (final c in _selectedClothing) c.id: c};

  List<String> get _selectedOrderedIds => _selectedClothing.map((e) => e.id).toList();

  void _togglePick(Clothing c) {
    setState(() {
      final i = _selectedClothing.indexWhere((e) => e.id == c.id);
      if (i >= 0) {
        _selectedClothing.removeAt(i);
      } else {
        _selectedClothing.add(c);
      }
    });
  }

  void _removeAt(int index) {
    setState(() {
      _selectedClothing.removeAt(index);
    });
  }

  void _clearSelection() {
    setState(_selectedClothing.clear);
  }

  void _reorderSelection(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedClothing.removeAt(oldIndex);
      _selectedClothing.insert(newIndex, item);
    });
  }

  Future<void> _openSaveDialog() async {
    if (_selectedClothing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择至少一件衣物')),
      );
      return;
    }
    _nameController.clear();
    _notesController.clear();
    _saveOccasion = null;

    // 用底部表单替代居中 Dialog：与键盘一起上移的 viewInsets 在 sheet 上可靠，避免 BOTTOM OVERFLOWED
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;
            return AnimatedPadding(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceLg,
                  AppTheme.spaceSm,
                  AppTheme.spaceLg,
                  AppTheme.spaceLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('保存搭配', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppTheme.spaceMd),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '搭配名称',
                        hintText: '例如：周末休闲',
                      ),
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Text('场合', style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppTheme.spaceXs),
                    Wrap(
                      spacing: AppTheme.spaceXs,
                      runSpacing: AppTheme.spaceXs,
                      children: _occasions.map((o) {
                        final sel = _saveOccasion == o;
                        return FilterChip(
                          label: Text(o),
                          selected: sel,
                          onSelected: (v) => setDialogState(() => _saveOccasion = v ? o : null),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        hintText: '选填',
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(sheetCtx, false),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        FilledButton(
                          onPressed: () => Navigator.pop(sheetCtx, true),
                          child: const Text('保存'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (ok != true || !mounted) {
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写搭配名称')),
      );
      return;
    }

    final ids = _selectedOrderedIds;
    final outfitId = _uuid.v4();
    setState(() => _saving = true);
    try {
      final repo = await ref.read(outfitRepositoryProvider.future);
      final outfit = Outfit(
        id: outfitId,
        name: name,
        clothingIds: ids,
        occasion: _saveOccasion,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        wornDates: const [],
        plannedDates: const [],
        isShared: false,
        imageUrl: null,
      );
      await repo.save(outfit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('搭配已保存')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('创建搭配'),
        actions: [
          TextButton(
            onPressed: _selectedClothing.isEmpty ? null : _clearSelection,
            child: const Text('清空'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spaceSm),
            child: FilledButton(
              onPressed: _saving ? null : _openSaveDialog,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text('加载衣物失败：$_loadError'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spaceMd,
                        AppTheme.spaceMd,
                        AppTheme.spaceMd,
                        AppTheme.spaceXs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '套装预览',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppTheme.spaceSm),
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? theme.colorScheme.surfaceContainerHigh
                                    : const Color(0xFFF5F2EC),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _selectedClothing.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                                        child: Text(
                                          '在下方点选衣物加入套装；再次点选可移除。\n'
                                          '可在列表中拖动调整顺序。',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.outline,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(AppTheme.spaceSm),
                                      child: OutfitClothingCollage(
                                        clothingIds: _selectedOrderedIds,
                                        clothingById: _clothingById,
                                        compact: false,
                                      ),
                                    ),
                            ),
                          ),
                          if (_selectedClothing.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spaceSm),
                            Text(
                              '已选（${_selectedClothing.length}）· 长按拖动排序',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceXs),
                            SizedBox(
                              height: 132,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  child: ReorderableListView.builder(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    buildDefaultDragHandles: false,
                                    itemCount: _selectedClothing.length,
                                    onReorder: _reorderSelection,
                                    proxyDecorator: (child, index, animation) {
                                      return AnimatedBuilder(
                                        animation: animation,
                                        builder: (context, _) {
                                          final t = Curves.easeInOut.transform(animation.value);
                                          return Transform.scale(
                                            scale: 1.0 + 0.04 * t,
                                            child: Material(
                                              elevation: 6 * t,
                                              color: Colors.transparent,
                                              shadowColor: Colors.black26,
                                              child: child,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    itemBuilder: (context, i) {
                                      final c = _selectedClothing[i];
                                      final ref = _cutoutRef(c);
                                      return ListTile(
                                        key: ValueKey<String>(c.id),
                                        dense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spaceSm,
                                        ),
                                        leading: SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: ColoredBox(
                                              color: const Color(0xFFE8E4DD),
                                              child: imageFromClothingRef(
                                                ref,
                                                fit: BoxFit.contain,
                                                placeholder: Icon(
                                                  Icons.checkroom_outlined,
                                                  size: 22,
                                                  color: theme.colorScheme.outline,
                                                ),
                                                errorBuilder: (ctx, e, s) => Icon(
                                                  Icons.broken_image_outlined,
                                                  color: theme.colorScheme.outline,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        subtitle: Text(
                                          c.category,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: '移除',
                                              onPressed: () => _removeAt(i),
                                              icon: const Icon(Icons.close),
                                            ),
                                            ReorderableDragStartListener(
                                              index: i,
                                              child: const Padding(
                                                padding: EdgeInsets.only(right: 4),
                                                child: Icon(Icons.drag_handle),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: _ClothingPickerPanel(
                        categories: _categories,
                        tabCategory: _tabCategory,
                        onCategoryChanged: (c) => setState(() => _tabCategory = c),
                        clothes: _filteredClothes,
                        imageRef: _cutoutRef,
                        selectedIds: _selectedIds,
                        onPick: _togglePick,
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ClothingPickerPanel extends StatelessWidget {
  const _ClothingPickerPanel({
    required this.categories,
    required this.tabCategory,
    required this.onCategoryChanged,
    required this.clothes,
    required this.imageRef,
    required this.selectedIds,
    required this.onPick,
  });

  final List<String> categories;
  final String tabCategory;
  final ValueChanged<String> onCategoryChanged;
  final List<Clothing> clothes;
  final String? Function(Clothing c) imageRef;
  final Set<String> selectedIds;
  final ValueChanged<Clothing> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceXs),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppTheme.spaceXs),
              itemBuilder: (context, i) {
                final c = categories[i];
                final sel = tabCategory == c;
                return ChoiceChip(
                  label: Text(c),
                  selected: sel,
                  onSelected: (_) => onCategoryChanged(c),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: clothes.isEmpty
                ? Center(
                    child: Text(
                      '该类别暂无衣物',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: AppTheme.spaceSm,
                      crossAxisSpacing: AppTheme.spaceSm,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: clothes.length,
                    itemBuilder: (context, i) {
                      final c = clothes[i];
                      final ref = imageRef(c);
                      final inSet = selectedIds.contains(c.id);
                      return Material(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onPick(c),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ColoredBox(
                                      color: const Color(0xFFE8E4DD),
                                      child: imageFromClothingRef(
                                        ref,
                                        fit: BoxFit.contain,
                                        placeholder: Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: theme.colorScheme.outline,
                                        ),
                                        errorBuilder: (ctx, e, s) => Icon(
                                          Icons.broken_image_outlined,
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                                    child: Text(
                                      c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                              if (inSet)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.92),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(Icons.check, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
