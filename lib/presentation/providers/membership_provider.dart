import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase/supabase_bootstrap_state.dart';
import '../../domain/models/membership_tier.dart';
import 'auth_session_provider.dart';

/// 从编译参数、Supabase 用户元数据解析是否 VIP（支付后由后端写入 app/user metadata）
MembershipTier _tierFromUser(User? user) {
  const fromDefine = String.fromEnvironment('MEMBERSHIP_TIER', defaultValue: '');
  if (fromDefine.trim().toLowerCase() == 'vip') {
    return MembershipTier.vip;
  }
  if (user == null) {
    return MembershipTier.free;
  }
  bool isVip(dynamic v) {
    if (v is bool) {
      return v;
    }
    if (v is String) {
      return v.toLowerCase() == 'vip' || v == '1' || v.toLowerCase() == 'true';
    }
    if (v is num) {
      return v != 0;
    }
    return false;
  }

  final um = user.userMetadata;
  if (um != null) {
    if (isVip(um['membership_tier']) || isVip(um['is_vip'])) {
      return MembershipTier.vip;
    }
  }
  final am = user.appMetadata;
  if (isVip(am['membership_tier']) || isVip(am['is_vip'])) {
    return MembershipTier.vip;
  }
  return MembershipTier.free;
}

/// 当前会员档位（随 [supabaseAuthSessionProvider] 会话变化重建）
final membershipTierProvider = Provider<MembershipTier>((ref) {
  ref.watch(supabaseAuthSessionProvider);
  if (!supabaseCloudEnabled) {
    return _tierFromUser(null);
  }
  try {
    return _tierFromUser(Supabase.instance.client.auth.currentUser);
  } catch (_) {
    return MembershipTier.free;
  }
});
