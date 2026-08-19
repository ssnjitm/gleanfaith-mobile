import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the currently selected tab in the MainShell bottom navigation.
///
/// Shared between the shell and the home page quick actions so a quick action
/// (e.g. "Take Quiz" or "Profile") can switch to the same tab the bottom
/// navigation bar would switch to.
final mainTabIndexProvider = StateProvider<int>((ref) => 0);