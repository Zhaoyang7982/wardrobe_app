import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/outfit.dart';

/// 已从「搭配」列表移除、但保留穿着记录的搭配，可恢复或彻底删除。
class OutfitRecycleBinPage extends ConsumerStatefulWidget {
  const OutfitRecycleBinPage({super.key});

  @override
  ConsumerState<OutfitRecycleBinPage> createState() => _OutfitRecycleBinPageState();
}

class _OutfitRecycleBinPageState extends ConsumerState<OutfitRecycleBinPage> {
  List<Outfit> _items = [];
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
      final repo = await ref.read(outfitRepositoryProvider.future);
      final all = await repo.getAllIncludingArchived();
      final recycled = all.where((o) => o.isArchived).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) {
        return;
      }
      setState(() {
        _items = recycled;
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

  Future<void> _restore(Outfit o) async {
    try {
      final repo = await ref.read(outfitRepositoryProvider.future);
      await repo.save(o.copyWith(isArchived: false));
      ref.invalidate(outfitRepositoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已恢复「${o.name}」至搭配列表')),
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

  Future<void> _showItemActions(Outfit o) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.unarchive_outlined),
                title: const Text('恢复至搭配列表'),
                onTap: () {
                  Navigator.pop(ctx);
                  _restore(o);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: Theme.of(ctx).colorScheme.error),
                title: Text('彻底删除', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _purge(o);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _purge(Outfit o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('彻底删除'),
        content: Text(
          '确定永久删除「${o.name}」？'
          '日历中的穿着记录将一并移除，且无法恢复。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('彻底删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    try {
      final repo = await ref.read(outfitRepositoryProvider.future);
      await repo.permanentlyDelete(o.id);
      ref.invalidate(outfitRepositoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已彻底删除')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('搭配回收站'),
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
              : _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceLg),
                        child: Text(
                          '暂无内容。\n'
                          '在「搭配」中移除、且曾在日历标记过「已穿」的搭配会出现在这里。',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        itemCount: _items.length,
                        separatorBuilder: (context, _) => const SizedBox(height: AppTheme.spaceXs),
                        itemBuilder: (context, i) {
                          final o = _items[i];
                          final wearDays = o.wornDates.length;
                          return Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spaceXs,
                                horizontal: AppTheme.spaceSm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(o.name),
                                    subtitle: Text('已穿记录 $wearDays 天'),
                                    onTap: () => context.push(AppRoutePaths.outfitDetail(o.id)),
                                    onLongPress: () => _showItemActions(o),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _restore(o),
                                          icon: const Icon(Icons.unarchive_outlined, size: 18),
                                          label: const Text('恢复至列表'),
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spaceXs),
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () => _purge(o),
                                          icon: Icon(Icons.delete_forever_outlined, size: 18, color: theme.colorScheme.error),
                                          label: Text('彻底删除', style: TextStyle(color: theme.colorScheme.error)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
