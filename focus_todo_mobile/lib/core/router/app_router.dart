import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../navigation/mobile_tab_shell.dart';
import '../../features/tasks/presentation/screens/completed_screen.dart';
import '../../features/tasks/presentation/screens/today_screen.dart';
import '../../features/tasks/presentation/screens/upcoming_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.todayPath,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.rootPath,
        redirect: (_, __) => AppRoutes.todayPath,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MobileTabShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.todayPath,
                name: AppRoutes.todayName,
                builder: (_, __) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.upcomingPath,
                name: AppRoutes.upcomingName,
                builder: (_, __) => const UpcomingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.completedPath,
                name: AppRoutes.completedName,
                builder: (_, __) => const CompletedScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
