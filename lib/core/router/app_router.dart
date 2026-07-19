import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/signin_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../common/features/home/presentation/pages/home_page.dart';
import '../common/features/splash/presentation/pages/splash_page.dart';
import 'route_names.dart';

class _AuthRedirect extends ChangeNotifier {
  AuthStatus status = AuthStatus.initial;

  void update(AuthStatus s) {
    if (s != status) {
      status = s;
      notifyListeners();
    }
  }
}

class AppRouter {
  static _AuthRedirect? _authRedirect;

  static _AuthRedirect get redirectNotifier {
    _authRedirect ??= _AuthRedirect();
    return _authRedirect!;
  }

  static GoRouter create() {
    return GoRouter(
      initialLocation: RouteNames.splash,
      refreshListenable: redirectNotifier,
      redirect: (context, state) {
        final authStatus = redirectNotifier.status;
        final location = state.matchedLocation;

        if (authStatus == AuthStatus.initial) {
          if (location != RouteNames.splash) {
            return RouteNames.splash;
          }
          return null;
        }

        if (authStatus == AuthStatus.authenticated) {
          if (location == RouteNames.splash || location == RouteNames.signin) {
            return RouteNames.home;
          }
          return null;
        }

        if (authStatus == AuthStatus.unauthenticated || authStatus == AuthStatus.error) {
          if (location == RouteNames.splash || location == RouteNames.home) {
            return RouteNames.signin;
          }
          return null;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouteNames.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: RouteNames.signin,
          builder: (context, state) => const SignInPage(),
        ),
        GoRoute(
          path: RouteNames.signup,
          builder: (context, state) => const SignUpPage(),
        ),
        GoRoute(
          path: RouteNames.verifyOtp,
          builder: (context, state) => const VerifyOtpPage(),
        ),
        GoRoute(
          path: RouteNames.forgotPassword,
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: RouteNames.resetPassword,
          builder: (context, state) => const ResetPasswordPage(),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: RouteNames.settings,
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    );
  }
}
