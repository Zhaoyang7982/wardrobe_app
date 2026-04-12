import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/sync/sync_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _isError = false;

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
      _message = null;
      _isError = false;
    });
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) {
        return;
      }
      if (res.session != null) {
        ref.invalidate(clothingRepositoryProvider);
        ref.invalidate(outfitRepositoryProvider);
        await ref.read(cloudWardrobeSyncProvider).flushIfOnline();
        ref.invalidate(syncPendingCountProvider);
        setState(() {
          _message = '注册成功，已自动登录';
          _isError = false;
        });
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          context.go(AppRoutePaths.wardrobe);
        }
      } else {
        setState(() {
          _message = '注册成功。若项目开启了邮箱验证，请查收邮件后再登录。';
          _isError = false;
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _message = e.message;
        _isError = true;
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
        _isError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
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
                  decoration: const InputDecoration(labelText: '密码（至少 6 位）'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return '密码至少 6 位';
                    }
                    return null;
                  },
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    style: TextStyle(
                      color: _isError ? Theme.of(context).colorScheme.error : null,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('注册'),
                ),
                TextButton(
                  onPressed: _loading ? null : () => context.pop(),
                  child: const Text('返回登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
