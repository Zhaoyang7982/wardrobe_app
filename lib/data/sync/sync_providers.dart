import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloud_wardrobe_sync.dart';

final cloudWardrobeSyncProvider = Provider<CloudWardrobeSync>((ref) {
  return CloudWardrobeSync();
});

/// 当前是否具备「非 none」网络能力（不等价于一定能连上公网）
final connectivityOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  Future<bool> check() async {
    final r = await connectivity.checkConnectivity();
    return r.any((e) => e != ConnectivityResult.none);
  }

  yield await check();
  await for (final _ in connectivity.onConnectivityChanged) {
    yield await check();
  }
});

final syncPendingCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(cloudWardrobeSyncProvider).pendingCount();
});
