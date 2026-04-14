import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/wardrobe_local_only_preference.dart';
import '../../data/supabase/supabase_bootstrap_state.dart';
import '../auth/auth_refresh_listenable.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/clothing/add_clothing_page.dart';
import '../../presentation/pages/clothing/edit_clothing_page.dart';
import '../../presentation/pages/clothing/clothing_detail_page.dart';
import '../../presentation/pages/home/calendar_tab_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/home/outfit_tab_page.dart';
import '../../presentation/pages/home/profile_tab_page.dart';
import '../../presentation/pages/home/wardrobe_tab_page.dart';
import '../../presentation/pages/onboarding_page.dart';
import '../../presentation/pages/outfit/create_outfit_page.dart';
import '../../presentation/pages/outfit/outfit_recycle_bin_page.dart';
import '../../presentation/pages/outfit/recommended_outfit_detail_page.dart';
import '../../presentation/pages/outfit_detail_page.dart';
import '../../presentation/pages/wardrobe/today_recommendation_page.dart';
import '../../domain/usecases/outfit_recommendation_usecase.dart';
import '../../presentation/pages/stats/stats_page.dart';
import '../../presentation/pages/travel_page.dart';
import 'web_nav_prefix.dart';

String _routeAbs(String path) {
  assert(path.startsWith('/'));
  final p = webNavPathPrefix;
  if (p.isEmpty) return path;
  return '$p$path';
}

/// 路由路径常量，跳转时优先使用此类避免硬编码散落
abstract final class AppRoutePaths {
  AppRoutePaths._();

  static String get onboarding => _routeAbs('/onboarding');
  static String get login => _routeAbs('/login');
  static String get register => _routeAbs('/register');
  static String get home => _routeAbs('/home');
  static String get wardrobe => _routeAbs('/wardrobe');
  static String get todayRecommendation => _routeAbs('/wardrobe/today-recommendation');

  /// Web 主导航内「今日推荐」Tab（仅 Web 构建注册对应 [StatefulShellBranch]）
  static String get todayRecommendationsTab => _routeAbs('/today-recommendations');
  static String get outfit => _routeAbs('/outfit');
  static String get calendar => _routeAbs('/calendar');
  static String get profile => _routeAbs('/profile');
  static String get clothingAdd => _routeAbs('/clothing/add');
  static String get outfitCreate => _routeAbs('/outfit/create');
  static String get outfitRecycleBin => _routeAbs('/outfit/recycle-bin');
  static String get travel => _routeAbs('/travel');
  static String get stats => _routeAbs('/stats');

  static String clothingDetail(String id) => _routeAbs('/clothing/$id');

  static String clothingEdit(String id) => _routeAbs('/clothing/$id/edit');

  static String outfitDetail(String id) => _routeAbs('/outfit/$id');

  /// 今日推荐等非已存搭配：用 [context.push] 并传 `extra: RecommendedOutfitBundle`
  static String get recommendedOutfitPreview => _routeAbs('/outfit/recommendation');
}

bool _isPublicPath(String loc) {
  return loc == AppRoutePaths.login ||
      loc == AppRoutePaths.register ||
      loc == AppRoutePaths.onboarding;
}

String? _authRedirect(BuildContext context, GoRouterState state) {
  // 未配置云端、或用户显式「仅本机」：不强制登录，数据以 Isar 为主
  if (!supabaseCloudEnabled || wardrobeLocalOnlyMode) {
    return null;
  }
  final loc = state.matchedLocation;
  final session = Supabase.instance.client.auth.currentSession;

  if (_isPublicPath(loc)) {
    if (session != null && (loc == AppRoutePaths.login || loc == AppRoutePaths.register)) {
      return AppRoutePaths.wardrobe;
    }
    return null;
  }

  if (session == null) {
    return AppRoutePaths.login;
  }
  return null;
}

/// 全局 [GoRouter] 与根导航器（全屏页需挂到根栈时使用）
abstract final class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: appAuthRefresh,
    // 已配置云端且未选「仅本机」时冷启动进登录页，引导使用账号；仅本机或未配置云端则进衣橱
    initialLocation: (!supabaseCloudEnabled || wardrobeLocalOnlyMode)
        ? AppRoutePaths.wardrobe
        : AppRoutePaths.login,
    redirect: _authRedirect,
    routes: <RouteBase>[
      if (webNavPathPrefix.isNotEmpty) ...[
        GoRoute(
          path: webNavPathPrefix,
          redirect: (_, _) => AppRoutePaths.wardrobe,
        ),
        GoRoute(
          path: '$webNavPathPrefix/',
          redirect: (_, _) => AppRoutePaths.wardrobe,
        ),
      ],
      GoRoute(
        path: AppRoutePaths.onboarding,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutePaths.register,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutePaths.home,
        redirect: (context, state) => AppRoutePaths.wardrobe,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomePage(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutePaths.wardrobe,
                builder: (context, state) => const WardrobeTabPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutePaths.outfit,
                builder: (context, state) => const OutfitTabPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutePaths.calendar,
                builder: (context, state) => const CalendarTabPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutePaths.stats,
                builder: (context, state) => const StatsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutePaths.profile,
                builder: (context, state) => const ProfileTabPage(),
              ),
            ],
          ),
          if (kIsWeb)
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutePaths.todayRecommendationsTab,
                  builder: (context, state) => const TodayRecommendationPage(),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: AppRoutePaths.clothingAdd,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddClothingPage(),
      ),
      GoRoute(
        path: _routeAbs('/clothing/:id/edit'),
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditClothingPage(clothingId: id);
        },
      ),
      GoRoute(
        path: _routeAbs('/clothing/:id'),
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClothingDetailPage(clothingId: id);
        },
      ),
      GoRoute(
        path: AppRoutePaths.todayRecommendation,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TodayRecommendationPage(),
      ),
      GoRoute(
        path: AppRoutePaths.outfitCreate,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateOutfitPage(),
      ),
      GoRoute(
        path: AppRoutePaths.outfitRecycleBin,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OutfitRecycleBinPage(),
      ),
      GoRoute(
        path: AppRoutePaths.recommendedOutfitPreview,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! RecommendedOutfitBundle) {
            return const Scaffold(
              body: Center(child: Text('无法打开该推荐')),
            );
          }
          return RecommendedOutfitDetailPage(bundle: extra);
        },
      ),
      GoRoute(
        path: _routeAbs('/outfit/:id'),
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OutfitDetailPage(outfitId: id);
        },
      ),
      GoRoute(
        path: AppRoutePaths.travel,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TravelPage(),
      ),
    ],
  );
}
