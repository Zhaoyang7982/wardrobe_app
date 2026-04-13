import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_refresh_listenable.dart';
import '../../../core/data/wardrobe_local_only_preference.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/supabase/supabase_bootstrap_state.dart';
import '../../../data/sync/sync_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _localOnlyLoading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      await setWardrobeLocalOnlyMode(false);
      ref.invalidate(clothingRepositoryProvider);
      ref.invalidate(outfitRepositoryProvider);
      try {
        await ref.read(cloudWardrobeSyncProvider).flushIfOnline();
      } catch (e, st) {
        debugPrint('登录后同步队列失败（已登录，可稍后重试）: $e\n$st');
      }
      ref.invalidate(syncPendingCountProvider);
      appAuthRefresh.requestRouterRefresh();
      if (!mounted) {
        return;
      }
      context.go(AppRoutePaths.wardrobe);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// 不登录进入本机衣橱（与云端数据隔离，卸载前持久保留）
  Future<void> _enterLocalOnlyMode() async {
    if (!supabaseCloudEnabled || _localOnlyLoading) {
      return;
    }
    setState(() => _localOnlyLoading = true);
    try {
      await setWardrobeLocalOnlyMode(true);
      ref.invalidate(clothingRepositoryProvider);
      ref.invalidate(outfitRepositoryProvider);
      ref.invalidate(syncPendingCountProvider);
      appAuthRefresh.requestRouterRefresh();
      if (!mounted) {
        return;
      }
      context.go(AppRoutePaths.wardrobe);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '进入本机模式失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() => _localOnlyLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: '邮箱'),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return '请输入邮箱';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: '密码'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('登录'),
                ),
                TextButton(
                  onPressed: _loading ? null : () => context.push(AppRoutePaths.register),
                  child: const Text('没有账号？注册'),
                ),
                if (supabaseCloudEnabled) ...[
                  const SizedBox(height: 32),
                  Divider(color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    '不想登录？',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '数据只保存在本机，不与任何云端账号同步；之后仍可在「我的」里登录以使用云端衣橱。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: (_loading || _localOnlyLoading) ? null : _enterLocalOnlyMode,
                    icon: _localOnlyLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.smartphone_outlined),
                    label: Text(_localOnlyLoading ? '正在进入…' : '仅在本机使用（不登录）'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
