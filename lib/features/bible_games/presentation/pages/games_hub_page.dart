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
import '../providers/bible_games_provider.dart';

/// Hub listing the five offline Bible games. Requires the bundled SQLite Bible
/// DB (unavailable in fallback mode, e.g. on web) — otherwise shows an empty
/// state.
class GamesHubPage extends ConsumerWidget {
  const GamesHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(bibleGamesDataProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Bible Games',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: data.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLg),
          child: ShimmerList(itemHeight: 92, itemCount: 5),
        ),
        error: (_, _) => AppErrorWidget(
          message: 'Could not load the offline Bible data.',
          onRetry: () => ref.invalidate(bibleGamesDataProvider),
        ),
        data: (gamesData) {
          if (gamesData.isEmpty) {
            return const AppEmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Bible data unavailable',
              subtitle:
                  'Bible games need the offline Bible database, which is not '
                  'available in this build.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            children: [
              _GameTile(
                icon: Icons.book_rounded,
                title: 'Guess the Book',
                subtitle: 'Read the opening words, pick the book',
                gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
                onTap: () => context.pushNamed(RouteNames.guessTheBook),
              ),
              _GameTile(
                icon: Icons.balance_rounded,
                title: 'Higher / Lower',
                subtitle: 'Tap the book with more chapters',
                gradient: const [Color(0xFFD97706), Color(0xFFF59E0B)],
                onTap: () => context.pushNamed(RouteNames.higherLower),
              ),
              _GameTile(
                icon: Icons.format_list_numbered_rounded,
                title: 'Book Order Race',
                subtitle: 'Tap the books in Bible order',
                gradient: const [Color(0xFF059669), Color(0xFF10B981)],
                onTap: () => context.pushNamed(RouteNames.bookOrderRace),
              ),
              _GameTile(
                icon: Icons.place_rounded,
                title: 'Find the Chapter',
                subtitle: 'Race the clock, tap the right chapter',
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
                  color: isDark
                      ? const Color(0xFF64748B)
                      : AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}