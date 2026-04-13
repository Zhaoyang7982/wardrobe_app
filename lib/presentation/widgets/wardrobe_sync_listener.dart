import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/wardrobe_local_only_preference.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/supabase/supabase_bootstrap_state.dart';
import '../../data/sync/sync_providers.dart';

/// 网络恢复时重放离线写队列并刷新仓储
class WardrobeSyncListener extends ConsumerWidget {
  const WardrobeSyncListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (supabaseCloudEnabled && !wardrobeLocalOnlyMode) {
      ref.listen(connectivityOnlineProvider, (prev, next) {
        next.whenData((online) async {
          if (online) {
            await ref.read(cloudWardrobeSyncProvider).flushIfOnline();
            ref.invalidate(clothingRepositoryProvider);
            ref.invalidate(outfitRepositoryProvider);
            ref.invalidate(syncPendingCountProvider);
          }
        });
      });
    }
    return child;
  }
}
