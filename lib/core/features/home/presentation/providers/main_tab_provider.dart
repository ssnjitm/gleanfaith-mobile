import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The MainShell bottom-navigation tabs, in display order.
///
/// The profile screen is deliberately NOT a tab — it is reached only from the
/// profile icon in a top bar. Refer to these constants instead of raw integers
/// so a reordering never silently sends a quick action to the wrong page.
class MainTab {
  const MainTab._();

  static const int home = 0;
  static const int library = 1;
  static const int quiz = 2;
  static const int bibleSearch = 3;
  static const int games = 4;

  /// Total number of bottom-navigation items.
  static const int count = 5;
}

/// Index of the currently selected tab in the MainShell bottom navigation.
///
/// Shared between the shell and the home page quick actions so a quick action
/// (e.g. "Take Quiz" or "Library") can switch to the same tab the bottom
/// navigation bar would switch to.
final mainTabIndexProvider = StateProvider<int>((ref) => MainTab.home);
