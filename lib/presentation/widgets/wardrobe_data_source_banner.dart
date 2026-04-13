import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_refresh_listenable.dart';
import '../../core/data/wardrobe_local_only_preference.dart';
import '../../data/supabase/supabase_bootstrap_state.dart';

/// 全局角标：当前数据来自本机 Isar 还是云端账号（随 [appAuthRefresh] 与登录态刷新）
class WardrobeDataSourceBanner extends StatelessWidget {
  const WardrobeDataSourceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appAuthRefresh,
      builder: (context, _) {
        final theme = Theme.of(context);
        final local = wardrobeLocalOnlyMode;
        final user = Supabase.instance.client.auth.currentUser;
        final email = user?.email?.trim();

        late final String text;
        late final IconData icon;
        if (!supabaseCloudEnabled) {
          icon = Icons.smartphone_outlined;
          text = '当前：本机（未配置云端）';
        } else if (local) {
          icon = Icons.smartphone_outlined;
          text = '当前：本机衣橱（与云端账号数据隔离）';
        } else if (email != null && email.isNotEmpty) {
          icon = Icons.cloud_done_outlined;
          text = '当前：云端 · $email';
        } else {
          icon = Icons.cloud_outlined;
          text = '当前：云端（未登录）';
        }

        return Material(
          color: theme.colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              children: [
                Icon(icon, size: 17, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
