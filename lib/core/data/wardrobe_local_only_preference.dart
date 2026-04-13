import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_refresh_listenable.dart';

const _kLocalOnly = 'wardrobe_local_only_mode';

/// 用户显式选择「仅本机、不强制登录」时为 true；默认 false（云端优先，已配置则须登录后使用）。
bool wardrobeLocalOnlyMode = false;

/// 在 [main] 中于 [runApp] 之前调用，供路由与仓储同步读取。
Future<void> loadWardrobeLocalOnlyPreference() async {
  final p = await SharedPreferences.getInstance();
  wardrobeLocalOnlyMode = p.getBool(_kLocalOnly) ?? false;
}

/// 写入偏好并触发 [GoRouter] 的 [refreshListenable]，调用方需自行 [ref.invalidate] 衣物/搭配等仓储。
Future<void> setWardrobeLocalOnlyMode(bool value) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(_kLocalOnly, value);
  wardrobeLocalOnlyMode = value;
  appAuthRefresh.requestRouterRefresh();
}
