import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase 项目 URL 与 anon key（勿把 service_role 放进客户端）
abstract final class SupabaseEnv {
  SupabaseEnv._();

  static String _fromDefine(String key) {
    switch (key) {
      case 'url':
        return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
      case 'anon':
        return const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
      default:
        return '';
    }
  }

  static String get url {
    final d = _fromDefine('url').trim();
    if (d.isNotEmpty) {
      return d;
    }
    return dotenv.env['SUPABASE_URL']?.trim() ?? '';
  }

  static String get anonKey {
    final d = _fromDefine('anon').trim();
    if (d.isNotEmpty) {
      return d;
    }
    return dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  }

  static bool get isConfigured {
    final u = url;
    final k = anonKey;
    return u.isNotEmpty && k.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://'));
  }
}
