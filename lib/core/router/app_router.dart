import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/main_nav/screens/main_shell_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../features/statistics/screens/statistics_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/add_transaction/screens/add_transaction_screen.dart';
import '../../features/debts/screens/debts_screen.dart';
import '../../features/budget/screens/budget_screen.dart';
import '../../features/goals/screens/goals_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/auth/screens/auth_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static GoRouter createRouter({required bool hasSeenOnboarding}) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: hasSeenOnboarding ? '/dashboard' : '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/auth',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AuthScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShellScreen(navigationShell: navigationShell);
          },
          branches: [
            // Branch 0: Dashboard
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: DashboardScreen(),
                  ),
                ),
              ],
            ),
            // Branch 1: Transactions
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/transactions',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: TransactionsScreen(),
                  ),
                ),
              ],
            ),
            // Branch 2: Statistics
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/statistics',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: StatisticsScreen(),
                  ),
                ),
              ],
            ),
            // Branch 3: Profile
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: ProfileScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/add-transaction',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AddTransactionScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.0, 0.15),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(
                position: animation.drive(offsetTween),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          ),
        ),
        GoRoute(
          path: '/debts',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const DebtsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.06, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(
                position: animation.drive(offsetTween),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          ),
        ),
        GoRoute(
          path: '/budget',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const BudgetScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.06, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(
                position: animation.drive(offsetTween),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          ),
        ),
        GoRoute(
          path: '/goals',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const GoalsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.06, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(
                position: animation.drive(offsetTween),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          ),
        ),
        GoRoute(
          path: '/edit-profile',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const EditProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.06, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(
                position: animation.drive(offsetTween),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          ),
        ),
      ],
    );
  }
}
