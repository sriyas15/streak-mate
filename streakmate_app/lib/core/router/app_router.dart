import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
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
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: _AuthRefreshStream(ref),
    redirect: (context, state) {
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
          if (state.matchedLocation.startsWith('/onboarding')) return null;
          return _onboardingRouteForStep(user.onboardingStep);
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
        builder: (context, state) => const _OnboardingPlaceholder(step: 'Welcome'),
      ),
      GoRoute(
        path: RouteNames.onboardingGoal,
        builder: (context, state) => const _OnboardingPlaceholder(step: 'Goal'),
      ),
      GoRoute(
        path: RouteNames.onboardingHabits,
        builder: (context, state) => const _OnboardingPlaceholder(step: 'Habits'),
      ),
      GoRoute(
        path: RouteNames.onboardingSubtasks,
        builder: (context, state) => const _OnboardingPlaceholder(step: 'Subtasks'),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const _HomePlaceholder(),
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
    case 5:
      return RouteNames.onboardingSubtasks;
    default:
      return RouteNames.onboardingWelcome;
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

class _OnboardingPlaceholder extends StatelessWidget {
  const _OnboardingPlaceholder({required this.step});
  final String step;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Onboarding: $step (to be built next)')),
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