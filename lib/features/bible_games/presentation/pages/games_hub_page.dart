import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/app_empty_state.dart';
import '../../../../core/common/widgets/app_error_widget.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/common/widgets/shimmer_widget.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/features/profile/presentation/widgets/profile_top_bar_button.dart';
import '../../domain/entities/bible_game_localization.dart';
import '../providers/bible_game_language_provider.dart';
import '../providers/bible_games_provider.dart';
import '../widgets/bible_game_language_toggle.dart';

/// Hub listing the four offline Bible games. Requires the bundled SQLite Bible
/// DB (unavailable in fallback mode, e.g. on web) — otherwise shows an empty
/// state.
///
/// The language defaults to the device locale; the `EN | NP` toggle in the
/// `AppBar` overrides it and the choice is remembered on the next launch. The
/// same toggle is repeated on every game page, so the switch is reachable
/// without coming back here.
class GamesHubPage extends ConsumerWidget {
  const GamesHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(localizedBibleGamesDataProvider);
    final strings = ref.watch(bibleGameStringsProvider);
    final language = ref.watch(bibleGameLanguageProvider);

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          strings.hubTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          BibleGameLanguageToggle(
            value: language,
            compact: true,
            onChanged: (value) => ref
                .read(bibleGameLanguageProvider.notifier)
                .setLanguage(value),
          ),
          const ProfileTopBarButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: data.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLg),
          child: ShimmerList(itemHeight: 92, itemCount: 4),
        ),
        error: (_, _) => AppErrorWidget(
          message: strings.loadFailed,
          onRetry: () => ref.invalidate(localizedBibleGamesDataProvider),
        ),
        data: (gamesData) {
          if (gamesData.isEmpty) {
            return AppEmptyState(
              icon: Icons.menu_book_outlined,
              title: strings.dataUnavailableTitle,
              subtitle: strings.dataUnavailableBody,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            children: [
              _LanguageCard(
                language: language,
                strings: strings,
                onChanged: (value) => ref
                    .read(bibleGameLanguageProvider.notifier)
                    .setLanguage(value),
              ),
              _GameTile(
                icon: Icons.book_rounded,
                title: strings.guessBookTitle,
                subtitle: strings.guessBookSubtitle,
                gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
                onTap: () => context.pushNamed(RouteNames.guessTheBook),
              ),
              _GameTile(
                icon: Icons.balance_rounded,
                title: strings.higherLowerTitle,
                subtitle: strings.higherLowerSubtitle,
                gradient: const [Color(0xFFD97706), Color(0xFFF59E0B)],
                onTap: () => context.pushNamed(RouteNames.higherLower),
              ),
              _GameTile(
                icon: Icons.format_list_numbered_rounded,
                title: strings.bookOrderTitle,
                subtitle: strings.bookOrderSubtitle,
                gradient: const [Color(0xFF059669), Color(0xFF10B981)],
                onTap: () => context.pushNamed(RouteNames.bookOrderRace),
              ),
              _GameTile(
                icon: Icons.place_rounded,
                title: strings.findChapterTitle,
                subtitle: strings.findChapterSubtitle,
                gradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                onTap: () => context.pushNamed(RouteNames.findTheChapter),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  final BibleGameLanguage language;
  final BibleGameStrings strings;
  final ValueChanged<BibleGameLanguage> onChanged;

  const _LanguageCard({
    required this.language,
    required this.strings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(bibleGameLanguageProvider.notifier);
    final isOverridden = notifier.isOverridden;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.gameLanguage,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOverridden
                          ? strings.gameLanguageManual
                          : strings.gameLanguageSystem,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BibleGameLanguageToggle(value: language, onChanged: onChanged),
            ],
          ),
          // Explicit, visible way back to "follow my phone". Tapping the active
          // segment of the toggle is a no-op on purpose, so the reset needs its
          // own control or the user has no visible way to undo the override.
          if (isOverridden) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: notifier.useDeviceLanguage,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  strings.gameLanguageUseDevice,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _GameTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                  child: Icon(icon, color: AppColors.textWhite, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF64748B) : AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
