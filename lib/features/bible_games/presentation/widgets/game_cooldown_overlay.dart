import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/extensions/context_extensions.dart';
import '../../../../core/common/widgets/app_empty_state.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/game_lives.dart';
import '../providers/bible_game_language_provider.dart';
import '../providers/game_lives_provider.dart';
import 'game_cooldown_dial.dart';

/// Full-screen lock shown instead of a game while its cooldown is running.
///
/// This widget owns **no** timer. The countdown comes from
/// [GameCooldownCountdown] (which re-derives from the wall clock) and the expiry
/// itself is handled by the provider-level clock in `GameLivesNotifier`, which
/// runs for the whole app rather than only while this screen is mounted. That
/// split is deliberate: a lock screen that can only end itself would never end
/// while the player was somewhere else.
class GameCooldownOverlay extends ConsumerWidget {
  final BibleGameKind kind;

  /// The game's title, already localized (shown on the lock screen).
  final String title;

  const GameCooldownOverlay({
    super.key,
    required this.kind,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(bibleGameStringsProvider);
    final language = ref.watch(bibleGameLanguageProvider);
    final lives = ref.watch(gameLivesProvider).value?[kind] ??
        const GameLives.full();

    // The provider clock refills the pool the moment the cooldown lapses, so
    // the page drops this overlay on its own — including while the player was
    // on another screen when it expired.
    if (!lives.isCooldownActiveAt(DateTime.now())) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppEmptyState(
              icon: Icons.lock_clock_rounded,
              title: strings.cooldownTitle,
              subtitle: '$title\n'
                  '${strings.cooldownBody(lives.formatCooldownAt(DateTime.now(), language), GameLives.maxLives)}',
            ),
            const SizedBox(height: 8),
            GameCooldownDial(lives: lives, isDark: isDark),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppButtonStyles.primaryGradientButton,
                onPressed: () => context.goNamed(RouteNames.gamesHub),
                child: Text(strings.goHome),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
