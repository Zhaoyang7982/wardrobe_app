import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/supabase/supabase_bootstrap_state.dart';
import '../../../data/sync/sync_providers.dart';

class ProfileTabPage extends ConsumerWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!supabaseCloudEnabled) {
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
            const SizedBox(height: 24),
            Text(
              '当前为纯本地模式（未配置或未启动云端）',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
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
