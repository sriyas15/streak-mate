import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/goal_selection_screen.dart';
import '../../features/onboarding/screens/habit_selection_screen.dart';
import '../../features/onboarding/screens/subtask_setup_screen.dart';
import '../../features/onboarding/screens/reminder_setup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import 'route_names.dart';

/// app_router.dart
/// go_router with redirect logic based on AuthState:
///   unknown          → splash (loading)
///   unauthenticated  → /login
///   authenticated + onboarding NOT completed → /onboarding/* (by step)
///   authenticated + onboarding completed     → /home
///
/// Onboarding screens themselves are added once that feature is built;
/// for now /onboarding/* routes point to placeholders so the redirect
/// logic can be wired and tested end-to-end with login/register.

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: _AuthRefreshStream(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final loggingInOrOut = state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.register;

      if (status == AuthStatus.unknown) {
        return RouteNames.splash;
      }

      if (status == AuthStatus.unauthenticated || status == AuthStatus.error) {
        return loggingInOrOut ? null : RouteNames.login;
      }

      if (status == AuthStatus.authenticated) {
        final user = authState.user;
        if (user != null && !user.onboardingCompleted) {
          final allowedRoute = _onboardingRouteForStep(user.onboardingStep);
          final requestedStep = _stepForOnboardingRoute(state.matchedLocation);

          if (state.matchedLocation.startsWith('/onboarding') &&
              requestedStep != null) {
            // Allow any step at or before the user's current server step,
            // PLUS one step ahead — so "Continue" buttons can always
            // advance forward before the server confirms the next step.
            // The server step only updates after a successful API call,
            // so blocking +1 navigation would freeze every "Continue" button.
            if (requestedStep <= user.onboardingStep + 1) return null;
          }
          return allowedRoute;
        }
        // Onboarding complete — keep authenticated users out of auth screens.
        if (loggingInOrOut || state.matchedLocation == RouteNames.splash) {
          return RouteNames.home;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.onboardingWelcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RouteNames.onboardingGoal,
        builder: (context, state) => const GoalSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.onboardingHabits,
        builder: (context, state) => const HabitSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.onboardingSubtasks,
        builder: (context, state) => const SubtaskSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.onboardingReminders,
        builder: (context, state) => const ReminderSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
    ],
  );
});

String _onboardingRouteForStep(int step) {
  switch (step) {
    case 1:
      return RouteNames.onboardingWelcome;
    case 2:
      return RouteNames.onboardingGoal;
    case 3:
      return RouteNames.onboardingHabits;
    case 4:
      return RouteNames.onboardingSubtasks;
    case 5:
      return RouteNames.onboardingReminders;
    default:
      return RouteNames.onboardingWelcome;
  }
}

/// Reverse of _onboardingRouteForStep — used so the redirect guard can
/// tell whether a requested /onboarding/* route is at or before the
/// user's current server-confirmed step (allowed) or ahead of it
/// (blocked, redirected back to their actual step).
int? _stepForOnboardingRoute(String route) {
  switch (route) {
    case RouteNames.onboardingWelcome:
      return 1;
    case RouteNames.onboardingGoal:
      return 2;
    case RouteNames.onboardingHabits:
      return 3;
    case RouteNames.onboardingSubtasks:
      return 4;
    case RouteNames.onboardingReminders:
      return 5;
    default:
      return null;
  }
}

/// Bridges Riverpod's authProvider stream into go_router's
/// Listenable-based refresh mechanism.
class _AuthRefreshStream extends ChangeNotifier {
  _AuthRefreshStream(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home dashboard (to be built later)')),
    );
  }
}