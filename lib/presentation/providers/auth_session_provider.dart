import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase/supabase_bootstrap_state.dart';

/// Supabase 会话流，用于在登录/登出后刷新依赖会话的 Provider（如会员档位）
final supabaseAuthSessionProvider = StreamProvider<Session?>((ref) {
  if (!supabaseCloudEnabled) {
    return Stream<Session?>.value(null);
  }
  final client = Supabase.instance.client;
  return client.auth.onAuthStateChange.map((e) => e.session);
});
