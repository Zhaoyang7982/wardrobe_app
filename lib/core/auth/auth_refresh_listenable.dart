import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase/supabase_bootstrap_state.dart';

AuthRefreshListenable? _authRefreshListenableInstance;

/// 在 [main] 完成 Supabase 初始化后再首次访问（例如通过 [AppRouter.router]）
AuthRefreshListenable get appAuthRefresh =>
    _authRefreshListenableInstance ??= AuthRefreshListenable();

/// 供 [GoRouter.refreshListenable] 使用，在 Supabase 会话变化时重建 redirect
final class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable() {
    if (supabaseCloudEnabled) {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        notifyListeners();
      });
    }
  }

  StreamSubscription<dynamic>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
