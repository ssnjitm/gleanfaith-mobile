import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/colors.dart';
import '../../../../../features/bible/presentation/pages/bible_search_page.dart';
import '../../../../../features/bible_games/presentation/pages/games_hub_page.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../quiz/presentation/pages/quiz_home_page.dart';
import '../providers/main_tab_provider.dart';
import 'home_page.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  /// Tab order must stay in sync with the `MainTab` constants and the
  /// `items` list below: Home, Library, Quiz, Bible Search, Games.
  final _pages = const [
    HomePage(),
    LibraryPage(),
    QuizHomePage(),
    BibleSearchPage(),
    GamesHubPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = ref.watch(mainTabIndexProvider);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgWhite,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(mainTabIndexProvider.notifier).state = index;
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: isDark ? Colors.grey[500] : AppColors.textLight,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              activeIcon: Icon(Icons.auto_stories_rounded),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz_outlined),
              activeIcon: Icon(Icons.quiz_rounded),
              label: 'Quiz',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Bible Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports_outlined),
              activeIcon: Icon(Icons.sports_esports_rounded),
              label: 'Games',
            ),
          ],
        ),
      ),
    );
  }
}
