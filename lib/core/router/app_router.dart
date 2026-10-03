import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/main_nav/screens/main_shell_screen.dart';
import '../../features/add_transaction/screens/add_transaction_screen.dart';
import '../../features/debts/screens/debts_screen.dart';
import '../../features/budget/screens/budget_screen.dart';
import '../../features/goals/screens/goals_screen.dart';

class AppRouter {
  AppRouter._();

  static GoRouter createRouter({required bool hasSeenOnboarding}) {
    return GoRouter(
      initialLocation: hasSeenOnboarding ? '/dashboard' : '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const MainShellScreen(initialIndex: 0),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const MainShellScreen(initialIndex: 1),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/statistics',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const MainShellScreen(initialIndex: 2),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const MainShellScreen(initialIndex: 3),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/add-transaction',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AddTransactionScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.0, 0.2),
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
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const DebtsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.05, 0.0),
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
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const BudgetScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.05, 0.0),
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
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const GoalsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.05, 0.0),
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
