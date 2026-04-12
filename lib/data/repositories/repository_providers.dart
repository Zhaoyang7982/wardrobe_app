import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/clothing_repository.dart';
import '../../domain/repositories/outfit_repository.dart';
import '../supabase/supabase_bootstrap_state.dart';
import '../sync/sync_providers.dart';
import 'local_repository_factory.dart';
import 'queued_cloud_clothing_repository.dart';
import 'queued_cloud_outfit_repository.dart';
import 'supabase_clothing_repository.dart';
import 'supabase_outfit_repository.dart';

/// 已配置且启动成功且已登录时使用 Supabase（含离线队列）；否则走本地（Isar / Web 内存）
final clothingRepositoryProvider = FutureProvider<ClothingRepository>((ref) async {
  if (supabaseCloudEnabled) {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final inner = SupabaseClothingRepository(Supabase.instance.client);
        final sync = ref.watch(cloudWardrobeSyncProvider);
        return QueuedCloudClothingRepository(inner, sync);
      }
    } catch (e, st) {
      debugPrint('Supabase 衣物仓储异常，回退本地: $e\n$st');
    }
  }
  return createLocalClothingRepository(ref);
});

final outfitRepositoryProvider = FutureProvider<OutfitRepository>((ref) async {
  if (supabaseCloudEnabled) {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final inner = SupabaseOutfitRepository(Supabase.instance.client);
        final sync = ref.watch(cloudWardrobeSyncProvider);
        return QueuedCloudOutfitRepository(inner, sync);
      }
    } catch (e, st) {
      debugPrint('Supabase 搭配仓储异常，回退本地: $e\n$st');
    }
  }
  return createLocalOutfitRepository(ref);
});
