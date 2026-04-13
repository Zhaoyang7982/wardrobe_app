import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/data/wardrobe_local_only_preference.dart';
import 'core/notifications/calendar_notifications_bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/theme/accent_color_provider.dart';
import 'core/theme/app_theme.dart';
import 'data/supabase/supabase_bootstrap_state.dart';
import 'data/supabase/supabase_env.dart';
import 'presentation/widgets/wardrobe_sync_listener.dart';

ThemeData _themeWithWebCjkTextTheme(ThemeData theme) {
  if (!kIsWeb) {
    return theme;
  }
  return theme.copyWith(
    textTheme: GoogleFonts.notoSansScTextTheme(theme.textTheme),
    primaryTextTheme: GoogleFonts.notoSansScTextTheme(theme.primaryTextTheme),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    try {
      await GoogleFonts.pendingFonts([GoogleFonts.notoSansSc()]);
    } catch (e, st) {
      debugPrint('Noto Sans SC preload skipped: $e\n$st');
    }
  }
  await _loadEnv();
  await _tryInitSupabase();
  await loadWardrobeLocalOnlyPreference();
  await bootstrapCalendarNotifications();
  runApp(const ProviderScope(child: WardrobeApp()));
}

Future<void> _tryInitSupabase() async {
  supabaseCloudEnabled = false;
  if (!SupabaseEnv.isConfigured) {
    return;
  }
  try {
    await Supabase.initialize(
      url: SupabaseEnv.url,
      anonKey: SupabaseEnv.anonKey,
    );
    supabaseCloudEnabled = true;
  } catch (e, st) {
    debugPrint('Supabase 初始化失败，将使用本地仓储: $e\n$st');
    supabaseCloudEnabled = false;
  }
}

/// 优先加载 [assets/env/app.env]（本地密钥，勿提交）；不存在则用模板 [app.env.example]
Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: 'assets/env/app.env');
  } catch (_) {
    await dotenv.load(fileName: 'assets/env/app.env.example');
  }
}

class WardrobeApp extends ConsumerWidget {
  const WardrobeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentArgb = ref.watch(accentColorArgbProvider);
    final lightTheme = accentArgb.when(
      data: (argb) => _themeWithWebCjkTextTheme(AppTheme.lightWithSeed(Color(argb))),
      loading: () => _themeWithWebCjkTextTheme(AppTheme.light),
      error: (e, _) => _themeWithWebCjkTextTheme(AppTheme.light),
    );
    final darkTheme = accentArgb.when(
      data: (argb) => _themeWithWebCjkTextTheme(AppTheme.darkWithSeed(Color(argb))),
      loading: () => _themeWithWebCjkTextTheme(AppTheme.dark),
      error: (e, _) => _themeWithWebCjkTextTheme(AppTheme.dark),
    );

    return WardrobeSyncListener(
      child: MaterialApp.router(
        title: AppConstants.appTitleShort,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
