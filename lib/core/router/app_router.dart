import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// 路由路径常量，跳转时优先使用此类避免硬编码散落
abstract final class AppRoutePaths {
  AppRoutePaths._();

  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const wardrobe = '/wardrobe';
  static const todayRecommendation = '/wardrobe/today-recommendation';

  /// Web 主导航内「今日推荐」Tab（仅 Web 构建注册对应 [StatefulShellBranch]）
  static const todayRecommendationsTab = '/today-recommendations';
  static const outfit = '/outfit';
  static const calendar = '/calendar';
  static const profile = '/profile';
  static const clothingAdd = '/clothing/add';
  static const outfitCreate = '/outfit/create';
  static const outfitRecycleBin = '/outfit/recycle-bin';
  static const travel = '/travel';
  static const stats = '/stats';

  static String clothingDetail(String id) => '/clothing/$id';

  static String clothingEdit(String id) => '/clothing/$id/edit';

  static String outfitDetail(String id) => '/outfit/$id';

  /// 今日推荐等非已存搭配：用 [context.push] 并传 `extra: RecommendedOutfitBundle`
  static const recommendedOutfitPreview = '/outfit/recommendation';
}

bool _isPublicPath(String loc) {
  return loc == AppRoutePaths.login ||
      loc == AppRoutePaths.register ||
      loc == AppRoutePaths.onboarding;
}

String? _authRedirect(BuildContext context, GoRouterState state) {
  if (!supabaseCloudEnabled) {
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
    initialLocation: AppRoutePaths.wardrobe,
    redirect: _authRedirect,
    routes: <RouteBase>[
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
        path: '/clothing/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditClothingPage(clothingId: id);
        },
      ),
      GoRoute(
        path: '/clothing/:id',
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
        path: '/outfit/:id',
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
