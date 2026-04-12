import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/share/save_file_helper.dart';
import '../../../core/share/share_bytes_helper.dart';
import '../../../core/share/wardrobe_csv_export.dart';
import '../../../core/share/wardrobe_grid_render.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/stored_image_ref.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/clothing.dart';
import '../../../domain/repositories/clothing_repository.dart';
import '../../providers/today_recommendation_provider.dart';

/// 衣橱列表：搜索、横向类别、网格、筛选面板、排序
class WardrobePage extends ConsumerStatefulWidget {
  const WardrobePage({super.key});

  @override
  ConsumerState<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends ConsumerState<WardrobePage> {
  static const _chipCategories = ['全部', '上衣', '下装', '裙装', '外套', '鞋子', '配饰', '包包'];

  static const _filterCategories = ['上衣', '下装', '裙装', '外套', '鞋子', '配饰', '包包'];
  static const _filterColors = [
    '黑', '白', '灰', '红', '橙', '黄', '绿', '蓝', '紫', '粉', '棕', '米', '卡其', '藏青',
  ];
  static const _filterSeasons = ['春', '夏', '秋', '冬'];
  static const _filterOccasions = ['日常', '工作', '运动', '正式', '约会', '旅行'];
  static const _filterStyles = ['休闲', '商务', '运动', '优雅', '街头'];

  static const _colorSwatches = <String, Color>{
    '黑': Color(0xFF212121),
    '白': Color(0xFFF5F5F5),
    '灰': Color(0xFF9E9E9E),
    '红': Color(0xFFE53935),
    '橙': Color(0xFFFF9800),
    '黄': Color(0xFFFFEB3B),
    '绿': Color(0xFF43A047),
    '蓝': Color(0xFF1E88E5),
    '紫': Color(0xFF8E24AA),
    '粉': Color(0xFFEC407A),
    '棕': Color(0xFF6D4C41),
    '米': Color(0xFFFFF8E1),
    '卡其': Color(0xFFC3B091),
    '藏青': Color(0xFF1A237E),
  };

  final _searchController = TextEditingController();

  String _quickCategory = '全部';
  String _searchKeyword = '';

  final Set<String> _panelCategories = {};
  final Set<String> _panelColors = {};
  final Set<String> _panelSeasons = {};
  final Set<String> _panelOccasions = {};
  final Set<String> _panelStyles = {};
  WardrobeSortMode _sort = WardrobeSortMode.recentAdded;

  List<Clothing> _items = [];
  bool _loading = true;
  String? _error;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final v = _searchController.text;
      if (!mounted || v == _searchKeyword) {
        return;
      }
      setState(() => _searchKeyword = v);
      _load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await ref.read(clothingRepositoryProvider.future);
      final list = await repo.listForWardrobe(
        quickCategory: _quickCategory,
        keyword: _searchKeyword,
        panelCategories: _panelCategories,
        panelColors: _panelColors,
        panelSeasons: _panelSeasons,
        panelOccasions: _panelOccasions,
        panelStyles: _panelStyles,
        sort: _sort,
      );
      if (mounted) {
        ref.invalidate(todayRecommendationProvider);
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  String _wardrobeExportFileStamp() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> _shareWardrobeCsvUtf8(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('正在生成 CSV…'), duration: Duration(seconds: 60)),
    );
    try {
      final repo = await ref.read(clothingRepositoryProvider.future);
      final list = await repo.getAll();
      if (!context.mounted) {
        return;
      }
      final bytes = wardrobeCsvBytes(list);
      final name = '衣橱清单_${_wardrobeExportFileStamp()}.csv';
      await shareFileBytes(bytes: bytes, fileName: name, mimeType: 'text/csv');
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
      }
    } catch (e) {
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text('分享失败：$e')));
      }
    }
  }

  Future<void> _saveWardrobeCsvUtf8(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = await ref.read(clothingRepositoryProvider.future);
      final list = await repo.getAll();
      if (!context.mounted) {
        return;
      }
      final bytes = wardrobeCsvBytes(list);
      final name = '衣橱清单_${_wardrobeExportFileStamp()}.csv';
      final ok = await saveBytesWithFilePicker(
        bytes: bytes,
        dialogTitle: '保存衣橱清单（UTF-8）',
        fileName: name,
        allowedExtensions: const ['csv'],
      );
      if (context.mounted && ok) {
        messenger.showSnackBar(const SnackBar(content: Text('已保存')));
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    }
  }

  Future<void> _shareWardrobeCsvUtf16(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('正在生成 CSV…'), duration: Duration(seconds: 60)),
    );
    try {
      final repo = await ref.read(clothingRepositoryProvider.future);
      final list = await repo.getAll();
      if (!context.mounted) {
        return;
      }
      final bytes = wardrobeCsvBytesUtf16Le(list);
      final name = '衣橱清单_WPS_${_wardrobeExportFileStamp()}.csv';
      await shareFileBytes(bytes: bytes, fileName: name, mimeType: 'text/csv');
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
      }
    } catch (e) {
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text('分享失败：$e')));
      }
    }
  }

  Future<void> _saveWardrobeCsvUtf16(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = await ref.read(clothingRepositoryProvider.future);
      final list = await repo.getAll();
      if (!context.mounted) {
        return;
      }
      final bytes = wardrobeCsvBytesUtf16Le(list);
      final name = '衣橱清单_WPS_${_wardrobeExportFileStamp()}.csv';
      final ok = await saveBytesWithFilePicker(
        bytes: bytes,
        dialogTitle: '保存衣橱清单（WPS/Excel 推荐）',
        fileName: name,
        allowedExtensions: const ['csv'],
      );
      if (context.mounted && ok) {
        messenger.showSnackBar(const SnackBar(content: Text('已保存')));
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    }
  }

  Future<void> _shareWardrobeOverviewPng(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('正在生成总览图（衣物较多时可能稍候）…'),
        duration: Duration(seconds: 120),
      ),
    );
    try {
      final repo = await ref.read(clothingRepositoryProvider.future);
      final list = await repo.getAll();
      if (list.isEmpty) {
        if (context.mounted) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(const SnackBar(content: Text('衣橱为空')));
        }
        return;
      }
      final png = await renderWardrobeOverviewPng(list);
      if (!context.mounted) {
        return;
      }
      messenger.hideCurrentSnackBar();
      if (png == null) {
        messenger.showSnackBar(const SnackBar(content: Text('生成图片失败')));
        return;
      }
      final name = '衣橱总览_${_wardrobeExportFileStamp()}.png';
      await shareFileBytes(bytes: png, fileName: name, mimeType: 'image/png');
    } catch (e) {
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text('分享失败：$e')));
      }
    }
  }

  Future<void> _saveWardrobeOverviewPng(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('正在生成总览图…'),
        duration: Duration(seconds: 120),
      ),
    );
    try {
      final repo = await ref.read(clothingRepositoryProvider.future);
      final list = await repo.getAll();
      if (list.isEmpty) {
        if (context.mounted) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(const SnackBar(content: Text('衣橱为空')));
        }
        return;
      }
      final png = await renderWardrobeOverviewPng(list);
      if (!context.mounted) {
        return;
      }
      messenger.hideCurrentSnackBar();
      if (png == null) {
        messenger.showSnackBar(const SnackBar(content: Text('生成图片失败')));
        return;
      }
      final name = '衣橱总览_${_wardrobeExportFileStamp()}.png';
      final ok = await saveBytesWithFilePicker(
        bytes: png,
        dialogTitle: '保存衣橱总览图',
        fileName: name,
        allowedExtensions: const ['png'],
      );
      if (context.mounted && ok) {
        messenger.showSnackBar(const SnackBar(content: Text('已保存')));
      }
    } catch (e) {
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    }
  }

  void _openFilterSheet() {
    var tempCat = Set<String>.from(_panelCategories);
    var tempColors = Set<String>.from(_panelColors);
    var tempSeasons = Set<String>.from(_panelSeasons);
    var tempOccasions = Set<String>.from(_panelOccasions);
    var tempStyles = Set<String>.from(_panelStyles);
    var tempSort = _sort;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppTheme.spaceMd,
                right: AppTheme.spaceMd,
                top: AppTheme.spaceSm,
                bottom: MediaQuery.paddingOf(context).bottom + AppTheme.spaceMd,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('排序', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppTheme.spaceXs),
                    SegmentedButton<WardrobeSortMode>(
                      segments: const [
                        ButtonSegment(
                          value: WardrobeSortMode.recentAdded,
                          label: Text('最近添加', overflow: TextOverflow.ellipsis),
                        ),
                        ButtonSegment(
                          value: WardrobeSortMode.mostWorn,
                          label: Text('最常穿', overflow: TextOverflow.ellipsis),
                        ),
                        ButtonSegment(
                          value: WardrobeSortMode.purchaseDate,
                          label: Text('购买时间', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      selected: {tempSort},
                      onSelectionChanged: (s) {
                        setModal(() => tempSort = s.first);
                      },
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    Text('类别（多选）', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppTheme.spaceXs),
                    Wrap(
                      spacing: AppTheme.spaceXs,
                      runSpacing: AppTheme.spaceXs,
                      children: _filterCategories.map((c) {
                        final sel = tempCat.contains(c);
                        return FilterChip(
                          label: Text(c),
                          selected: sel,
                          onSelected: (v) {
                            setModal(() {
                              if (v) {
                                tempCat.add(c);
                              } else {
                                tempCat.remove(c);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Text('颜色（多选）', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppTheme.spaceXs),
                    Wrap(
                      spacing: AppTheme.spaceXs,
                      runSpacing: AppTheme.spaceXs,
                      children: _filterColors.map((c) {
                        final sel = tempColors.contains(c);
                        final bg = _colorSwatches[c] ?? Colors.grey;
                        return FilterChip(
                          avatar: CircleAvatar(radius: 10, backgroundColor: bg),
                          label: Text(c),
                          selected: sel,
                          onSelected: (v) {
                            setModal(() {
                              if (v) {
                                tempColors.add(c);
                              } else {
                                tempColors.remove(c);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Text('季节（多选）', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppTheme.spaceXs),
                    _chipWrap(_filterSeasons, tempSeasons, setModal),
                    const SizedBox(height: AppTheme.spaceMd),
                    Text('场合（多选）', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppTheme.spaceXs),
                    _chipWrap(_filterOccasions, tempOccasions, setModal),
                    const SizedBox(height: AppTheme.spaceMd),
                    Text('风格（多选）', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppTheme.spaceXs),
                    _chipWrap(_filterStyles, tempStyles, setModal),
                    const SizedBox(height: AppTheme.spaceLg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModal(() {
                                tempCat.clear();
                                tempColors.clear();
                                tempSeasons.clear();
                                tempOccasions.clear();
                                tempStyles.clear();
                              });
                            },
                            child: const Text('清空筛选'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _panelCategories
                                  ..clear()
                                  ..addAll(tempCat);
                                _panelColors
                                  ..clear()
                                  ..addAll(tempColors);
                                _panelSeasons
                                  ..clear()
                                  ..addAll(tempSeasons);
                                _panelOccasions
                                  ..clear()
                                  ..addAll(tempOccasions);
                                _panelStyles
                                  ..clear()
                                  ..addAll(tempStyles);
                                _sort = tempSort;
                              });
                              Navigator.pop(ctx);
                              _load();
                            },
                            child: const Text('应用'),
                          ),
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
  }

  /// 衣橱首页入口：进入「今日推荐」独立页，不占大块纵向空间。
  Widget _todayRecommendationEntry(ThemeData theme) {
    final async = ref.watch(todayRecommendationProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        0,
        AppTheme.spaceMd,
        AppTheme.spaceXs,
      ),
      child: Row(
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            onPressed: () => context.push(AppRoutePaths.todayRecommendation),
            icon: Icon(Icons.wb_sunny_outlined, size: 20, color: theme.colorScheme.primary),
            label: const Text('今日推荐'),
          ),
          const SizedBox(width: 4),
          async.when(
            data: (r) {
              if (r.outfits.isEmpty) {
                return Text(
                  '暂无',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                );
              }
              return Text(
                '${r.outfits.length} 套',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
            loading: () => SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            error: (err, stack) => Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  static Widget _chipWrap(
    List<String> labels,
    Set<String> set,
    void Function(void Function()) setModal,
  ) {
    return Wrap(
      spacing: AppTheme.spaceXs,
      runSpacing: AppTheme.spaceXs,
      children: labels.map((c) {
        final sel = set.contains(c);
        return FilterChip(
          label: Text(c),
          selected: sel,
          onSelected: (v) {
            setModal(() {
              if (v) {
                set.add(c);
              } else {
                set.remove(c);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('衣橱'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: '导出 / 分享',
            onSelected: (value) {
              switch (value) {
                case 'share_csv_u8':
                  _shareWardrobeCsvUtf8(context);
                  break;
                case 'save_csv_u8':
                  _saveWardrobeCsvUtf8(context);
                  break;
                case 'share_csv_u16':
                  _shareWardrobeCsvUtf16(context);
                  break;
                case 'save_csv_u16':
                  _saveWardrobeCsvUtf16(context);
                  break;
                case 'share_png':
                  _shareWardrobeOverviewPng(context);
                  break;
                case 'save_png':
                  _saveWardrobeOverviewPng(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                height: 36,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('CSV', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'share_csv_u8',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.share_outlined, size: 22),
                  title: const Text('分享 UTF-8 CSV'),
                  subtitle: const Text('系统分享（微信等）', style: TextStyle(fontSize: 11)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'save_csv_u8',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.save_alt_outlined, size: 22),
                  title: const Text('保存 UTF-8 CSV…'),
                  subtitle: const Text('自选文件夹', style: TextStyle(fontSize: 11)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'share_csv_u16',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.table_view_outlined, size: 22),
                  title: const Text('分享 WPS/Excel CSV'),
                  subtitle: const Text('UTF-16，双击不易乱码', style: TextStyle(fontSize: 11)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'save_csv_u16',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.save_outlined, size: 22),
                  title: const Text('保存 WPS/Excel CSV…'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem(
                enabled: false,
                height: 36,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('图片', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'share_png',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.image_outlined, size: 22),
                  title: const Text('分享衣橱总览图'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'save_png',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.photo_size_select_large_outlined, size: 22),
                  title: const Text('保存总览图…'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _panelCategories.isNotEmpty ||
                  _panelColors.isNotEmpty ||
                  _panelSeasons.isNotEmpty ||
                  _panelOccasions.isNotEmpty ||
                  _panelStyles.isNotEmpty,
              smallSize: 8,
              child: const Icon(Icons.tune),
            ),
            onPressed: _openFilterSheet,
            tooltip: '筛选',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              AppTheme.spaceSm,
              AppTheme.spaceMd,
              AppTheme.spaceXs,
            ),
            child: SearchBar(
              controller: _searchController,
              hintText: '搜索名称、品牌…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchKeyword.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
              ],
            ),
          ),
          _todayRecommendationEntry(theme),
          // 横向类别 Chip：高度须容纳中文字体行高；过小会出现「有时只剩半字」
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              itemCount: _chipCategories.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppTheme.spaceXs),
              itemBuilder: (context, i) {
                final c = _chipCategories[i];
                final selected = _quickCategory == c;
                return Center(
                  child: ChoiceChip(
                    label: AppTheme.filterChipLabel(c),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _quickCategory = c);
                      _load();
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.standard,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Expanded(child: _buildBody(theme)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_wardrobe',
        onPressed: () async {
          await context.push(AppRoutePaths.clothingAdd);
          if (mounted) {
            _load();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
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
      );
    }
    if (_items.isEmpty) {
      return _buildEmpty(theme);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd,
          0,
          AppTheme.spaceMd,
          88,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppTheme.spaceMd,
          crossAxisSpacing: AppTheme.spaceMd,
          childAspectRatio: 0.72,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final c = _items[index];
          return _WardrobeItemCard(
            clothing: c,
            colorSwatches: _colorSwatches,
            onTap: () => context.push(AppRoutePaths.clothingDetail(c.id)),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.checkroom_outlined,
                  size: 96,
                  color: theme.colorScheme.outline.withValues(alpha: 0.45),
                ),
                const SizedBox(height: AppTheme.spaceLg),
                Text(
                  '衣橱还是空的',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Text(
                  '添加第一件衣物，开始管理你的搭配',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXl),
                FilledButton.icon(
                  onPressed: () async {
                    await context.push(AppRoutePaths.clothingAdd);
                    if (mounted) {
                      _load();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('添加第一件衣物'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WardrobeItemCard extends StatelessWidget {
  const _WardrobeItemCard({
    required this.clothing,
    required this.colorSwatches,
    required this.onTap,
  });

  final Clothing clothing;
  final Map<String, Color> colorSwatches;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = clothing.croppedImageUrl ?? clothing.imageUrl;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFE8E4DD),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? imageFromClothingRef(
                        imageUrl,
                        fit: BoxFit.contain,
                        placeholder: Icon(
                          Icons.image_not_supported_outlined,
                          size: 40,
                          color: theme.colorScheme.outline,
                        ),
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: theme.colorScheme.outline,
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported_outlined,
                        size: 40,
                        color: theme.colorScheme.outline,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceSm,
                AppTheme.spaceXs,
                AppTheme.spaceSm,
                AppTheme.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clothing.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: clothing.colors.take(4).map((name) {
                      final col = colorSwatches[name];
                      return Tooltip(
                        message: name,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: col ?? theme.colorScheme.outline,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
