import 'package:flutter/foundation.dart';
import 'package:glean_faith_app/features/bible/presentation/pages/bible_search_page.dart';
import 'package:glean_faith_app/features/bible/presentation/pages/bible_topic_detail_page.dart';
import 'package:glean_faith_app/features/bible/presentation/pages/bible_verse_detail_page.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/signin_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../features/home/presentation/pages/main_shell.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/quiz/presentation/pages/quiz_detail_page.dart';
import '../../features/quiz/presentation/pages/quiz_play_page.dart';
import '../../features/quiz/presentation/pages/quiz_result_page.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../../features/library/presentation/pages/library_detail_page.dart';
import '../../features/library/domain/entities/content_item.dart';
import '../../features/crosspuzzle/presentation/pages/crosspuzzle_home_page.dart';
import '../../features/crosspuzzle/presentation/pages/crosspuzzle_my_puzzles_page.dart';
import '../../features/crosspuzzle/presentation/pages/crosspuzzle_play_page.dart';
import '../../features/crosspuzzle/presentation/pages/crosspuzzle_result_page.dart';
import '../../features/crosspuzzle/domain/entities/crosspuzzle_entities.dart';
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
          builder: (context, state) => const MainShell(),
        ),
        GoRoute(
          path: RouteNames.settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: RouteNames.quizDetail,
          builder: (context, state) =>
              QuizDetailPage(quizScheduleId: state.extra as String? ?? ''),
        ),
        GoRoute(
          path: RouteNames.quizPlay,
          builder: (context, state) =>
              QuizPlayPage(sessionId: state.extra as String? ?? ''),
        ),
        GoRoute(
          path: RouteNames.quizResult,
          builder: (context, state) => QuizResultPage(
            result: state.extra == null ? null : state.extra as dynamic,
          ),
        ),
        GoRoute(
          path: RouteNames.library,
          builder: (context, state) => const LibraryPage(),
        ),
        GoRoute(
          path: RouteNames.libraryDetail,
          builder: (context, state) => LibraryDetailPage(
            item: state.extra is ContentItem
                ? state.extra! as ContentItem
                : const ContentItem(
                    id: '',
                    title: 'Content',
                    body: '',
                    type: 'written',
                  ),
          ),
        ),
        GoRoute(
    path: RouteNames.bibleSearch,
    name: RouteNames.bibleSearch,
    builder: (context, state) => const BibleSearchPage(),
  ),
  GoRoute(
    path: RouteNames.bibleTopicDetail,
    name: RouteNames.bibleTopicDetail,
    builder: (context, state) {
      final topic = state.pathParameters['topic']!;
      return BibleTopicDetailPage(topicName: topic);
    },
  ),
  GoRoute(
    path: RouteNames.bibleVerseDetail,
    name: RouteNames.bibleVerseDetail,
    builder: (context, state) {
      final book = state.pathParameters['book']!;
      final chapter = int.parse(state.pathParameters['chapter']!);
      final verse = int.parse(state.pathParameters['verse']!);
      return BibleVerseDetailPage(
        book: book,
        chapter: chapter,
        verse: verse,
      );
    },
  ),
        GoRoute(
          path: RouteNames.crossPuzzle,
          name: RouteNames.crossPuzzle,
          builder: (context, state) => const CrossPuzzleHomePage(),
        ),
        GoRoute(
          path: RouteNames.crossPuzzleMyPuzzles,
          name: RouteNames.crossPuzzleMyPuzzles,
          builder: (context, state) => const CrossPuzzleMyPuzzlesPage(),
        ),
        GoRoute(
          path: RouteNames.crossPuzzlePlay,
          name: RouteNames.crossPuzzlePlay,
          builder: (context, state) {
            final extra = state.extra;
            final params = extra is Map<String, dynamic>
                ? extra
                : const <String, dynamic>{};
            return CrossPuzzlePlayPage(
              puzzleId: params['id'] as String? ?? '',
              title: params['title'] as String? ?? 'Crossword',
            );
          },
        ),
        GoRoute(
          path: RouteNames.crossPuzzleResult,
          name: RouteNames.crossPuzzleResult,
          builder: (context, state) => CrossPuzzleResultPage(
            result: state.extra is CrossPuzzleCompleteResult
                ? state.extra as CrossPuzzleCompleteResult
                : null,
          ),
        ),
      ],
    );
  }
}
