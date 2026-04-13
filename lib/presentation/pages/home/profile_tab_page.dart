import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/wardrobe_local_only_preference.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/supabase/supabase_bootstrap_state.dart';
import '../../../data/sync/sync_providers.dart';

class ProfileTabPage extends ConsumerStatefulWidget {
  const ProfileTabPage({super.key});

  @override
  ConsumerState<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends ConsumerState<ProfileTabPage> {
  bool _modeToggleBusy = false;

  Future<void> _invalidateRepos() async {
    ref.invalidate(clothingRepositoryProvider);
    ref.invalidate(outfitRepositoryProvider);
    ref.invalidate(syncPendingCountProvider);
  }

  Future<void> _setLocalOnly(bool next) async {
    if (_modeToggleBusy) {
      return;
    }
    setState(() => _modeToggleBusy = true);
    try {
      if (next) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('切换到仅本机？'),
            content: const Text(
              '将退出当前账号，衣橱数据以本机 Isar 为准，不再与云端同步；换机或重装后无法从账号恢复。\n\n'
              '需要多端同步时请关闭此选项并重新登录。',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
            ],
          ),
        );
        if (ok != true || !mounted) {
          return;
        }
        await Supabase.instance.client.auth.signOut();
        await ref.read(cloudWardrobeSyncProvider).clearCacheAndQueue();
        await setWardrobeLocalOnlyMode(true);
        await _invalidateRepos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已切换为仅本机模式')));
        }
      } else {
        await setWardrobeLocalOnlyMode(false);
        await _invalidateRepos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已关闭仅本机模式，未登录时将跳转登录页')));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _modeToggleBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!supabaseCloudEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const _ThemeAccentSection(),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '以登录后的云端为主',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前未启用 Supabase（未配置或初始化失败），应用只能使用本机数据库，无法多端同步。\n\n'
                      '请在项目里添加 assets/env/app.env，写入有效的 SUPABASE_URL 与 SUPABASE_ANON_KEY，'
                      '重新编译并安装到手机（iOS 与 Android 相同）。配置成功后启动将要求登录，数据以云端为主、本机作缓存与离线队列。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('搭配回收站'),
              subtitle: const Text('恢复或彻底删除已移除的搭配'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutePaths.outfitRecycleBin),
            ),
          ],
        ),
      );
    }

    if (wardrobeLocalOnlyMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const _ThemeAccentSection(),
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '已开启「仅本机模式」：未登录，数据仅存本机，不与账号同步。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              secondary: _modeToggleBusy ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_outlined),
              title: const Text('使用云端与登录'),
              subtitle: const Text('打开后将关闭仅本机，并按账号使用云端（多端同步）'),
              value: !wardrobeLocalOnlyMode,
              onChanged: _modeToggleBusy ? null : (v) { if (v) _setLocalOnly(false); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('搭配回收站'),
              subtitle: const Text('恢复或彻底删除已移除的搭配'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutePaths.outfitRecycleBin),
            ),
          ],
        ),
      );
    }

    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? user?.id ?? '—';
    final pendingAsync = ref.watch(syncPendingCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _ThemeAccentSection(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('搭配回收站'),
            subtitle: const Text('恢复或彻底删除已移除的搭配'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutePaths.outfitRecycleBin),
          ),
          ListTile(
            title: const Text('账号'),
            subtitle: Text(email),
          ),
          pendingAsync.when(
            data: (n) => ListTile(
              title: const Text('待同步操作'),
              subtitle: Text(n == 0 ? '无' : '$n 条将在联网后自动上传'),
            ),
            loading: () => const ListTile(
              title: Text('待同步操作'),
              subtitle: SizedBox(height: 2, child: LinearProgressIndicator()),
            ),
            error: (e, _) => ListTile(title: const Text('待同步操作'), subtitle: Text('读取失败: $e')),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: _modeToggleBusy ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.smartphone),
            title: const Text('仅使用本机数据'),
            subtitle: const Text('不强制登录；数据仅存本机，无多端同步。默认关闭，以云端为主。'),
            value: wardrobeLocalOnlyMode,
            onChanged: _modeToggleBusy ? null : (v) { if (v) _setLocalOnly(true); },
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () async {
              await ref.read(cloudWardrobeSyncProvider).flushIfOnline();
              ref.invalidate(clothingRepositoryProvider);
              ref.invalidate(outfitRepositoryProvider);
              ref.invalidate(syncPendingCountProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已尝试同步')));
              }
            },
            child: const Text('立即同步'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              await ref.read(cloudWardrobeSyncProvider).clearCacheAndQueue();
              ref.invalidate(clothingRepositoryProvider);
              ref.invalidate(outfitRepositoryProvider);
              ref.invalidate(syncPendingCountProvider);
            },
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }
}

class _ThemeAccentSection extends ConsumerWidget {
  const _ThemeAccentSection();

  static String _labelForArgb(int argb) {
    for (final p in kAccentColorPresets) {
      if (p.argb == argb) {
        return p.label;
      }
    }
    return '自定义';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(accentColorArgbProvider);
    final currentArgb = async.valueOrNull ?? kDefaultAccentArgb;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('主题色', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              async.when(
                data: (argb) => '当前：${_labelForArgb(argb)} · 按钮与强调色会随选择更新',
                loading: () => '正在读取偏好…',
                error: (e, _) => '读取失败，使用默认色',
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final p in kAccentColorPresets)
                  Tooltip(
                    message: p.label,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => ref.read(accentColorArgbProvider.notifier).setAccentArgb(p.argb),
                        customBorder: const CircleBorder(),
                        child: Ink(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(p.argb),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: p.argb == currentArgb
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(alpha: 0.35),
                              width: p.argb == currentArgb ? 3 : 1,
                            ),
                          ),
                          child: p.argb == currentArgb
                              ? Icon(Icons.check, color: _contrastIconOn(Color(p.argb)), size: 22)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (currentArgb != kDefaultAccentArgb) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => ref.read(accentColorArgbProvider.notifier).resetToDefault(),
                  child: const Text('恢复默认'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 在有色圆上画勾，选黑或白以保证对比度
  static Color _contrastIconOn(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.55 ? Colors.black87 : Colors.white;
  }
}
