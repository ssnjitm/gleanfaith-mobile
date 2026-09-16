import 'package:flutter/widgets.dart';
import 'package:glean_faith_app/features/bible/presentation/pages/bible_reader_page.dart';
import 'package:glean_faith_app/features/bible/presentation/pages/bible_chapter_list_page.dart';
import 'package:glean_faith_app/features/bible/presentation/pages/bible_reading_page.dart';
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
import '../../features/course/presentation/pages/courses_page.dart';
import '../../features/course/presentation/pages/course_learn_page.dart';
import '../../features/course/presentation/pages/course_content_page.dart';
import '../../features/course/presentation/pages/course_quiz_play_page.dart';
import '../../features/course/presentation/pages/course_quiz_review_page.dart';
import '../../features/course/domain/entities/course_progress_entities.dart';
import '../../features/notification/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/crosspuzzle/presentation/pages/crosspuzzle_home_page.dart';
import '../../features/crosspuzzle/presentation/pages/crosspuzzle_my_puzzles_page.dart';
import '../../features/crosspuzzle/presentation/pages/crosspuzzle_play_page.dart';
import '../../features/crosspuzzle/presentation/pages/crosspuzzle_result_page.dart';
import '../../features/crosspuzzle/domain/entities/crosspuzzle_entities.dart';
import '../../features/bible_games/presentation/pages/games_hub_page.dart';
import '../../features/bible_games/presentation/pages/guess_book_page.dart';
import '../../features/bible_games/presentation/pages/higher_lower_page.dart';
import '../../features/bible_games/presentation/pages/book_order_page.dart';
import '../../features/bible_games/presentation/pages/find_chapter_page.dart';
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

  /// Global route observer used by pages that need to refresh their data
  /// when they regain visibility (e.g. the crossword journey after a play).
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static _AuthRedirect get redirectNotifier {
    _authRedirect ??= _AuthRedirect();
    return _authRedirect!;
  }

  static GoRouter create() {
    return GoRouter(
      initialLocation: RouteNames.splash,
      refreshListenable: redirectNotifier,
      observers: [routeObserver],
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
          path: RouteNames.notifications,
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: RouteNames.profileEdit,
          builder: (context, state) => const EditProfilePage(),
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
          path: RouteNames.courses,
          builder: (context, state) => const CoursesPage(),
        ),
        GoRoute(
          path: RouteNames.courseDetail,
          builder: (context, state) => CourseLearnPage(
            courseId: state.extra as String? ?? '',
          ),
        ),
        GoRoute(
          path: RouteNames.courseContent,
          builder: (context, state) {
            final extra = state.extra;
            return CourseContentPage(
              args: extra is CourseContentViewArgs ? extra : null,
            );
          },
        ),
        GoRoute(
          path: RouteNames.courseQuizPlay,
          builder: (context, state) {
            final extra = state.extra;
            return CourseQuizPlayPage(
              args: extra is CourseQuizPlayArgs ? extra : null,
            );
          },
        ),
        GoRoute(
          path: RouteNames.courseQuizReview,
          builder: (context, state) {
            final extra = state.extra;
            return CourseQuizReviewPage(
              args: extra is CourseQuizReviewArgs ? extra : null,
            );
          },
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
    path: RouteNames.bibleReader,
    name: RouteNames.bibleReader,
    builder: (context, state) => const BibleReaderPage(),
  ),
  GoRoute(
    path: RouteNames.bibleChapters,
    name: RouteNames.bibleChapters,
    builder: (context, state) =>
        BibleChapterListPage(book: state.pathParameters['book']!),
  ),
  GoRoute(
    path: RouteNames.bibleChapter,
    name: RouteNames.bibleChapter,
    builder: (context, state) => BibleReadingPage(
      book: state.pathParameters['book']!,
      chapter: int.parse(state.pathParameters['chapter']!),
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
        GoRoute(
          path: RouteNames.gamesHub,
          name: RouteNames.gamesHub,
          builder: (context, state) => const GamesHubPage(),
        ),
        GoRoute(
          path: RouteNames.guessTheBook,
          name: RouteNames.guessTheBook,
          builder: (context, state) => const GuessBookPage(),
        ),
        GoRoute(
          path: RouteNames.higherLower,
          name: RouteNames.higherLower,
          builder: (context, state) => const HigherLowerPage(),
        ),
        GoRoute(
          path: RouteNames.bookOrderRace,
          name: RouteNames.bookOrderRace,
          builder: (context, state) => const BookOrderPage(),
        ),
        GoRoute(
          path: RouteNames.findTheChapter,
          name: RouteNames.findTheChapter,
          builder: (context, state) => const FindChapterPage(),
        ),
      ],
    );
  }
}
