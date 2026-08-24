import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../common/widgets/app_error_widget.dart';
import '../../../../common/extensions/datetime_extensions.dart';
import '../../../../router/route_names.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../features/leaderboard/presentation/providers/leaderboard_provider.dart';
import '../../../home/presentation/widgets/stats_card.dart';
import '../../../../../features/profile/presentation/providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(profileProvider.notifier).load();
      final ranking = ref.read(leaderboardProvider);
      if (ranking.status == LeaderboardStatus.initial) {
        ref.read(leaderboardProvider.notifier).load();
      }
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(profileProvider.notifier).load(),
      ref.read(leaderboardProvider.notifier).load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authUser = ref.watch(authProvider).user;
    final profile = ref.watch(profileProvider).profile;
    final stats = ref.watch(profileProvider).stats;
    final ranking = ref.watch(leaderboardProvider).myRanking;

    final name = profile?.fullName ?? authUser?.fullName ?? 'User';
    final email = profile?.email ?? authUser?.email ?? '';
    final avatarUrl = profile?.avatar ?? authUser?.avatar;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDark ? Colors.grey[400] : AppColors.textMuted,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: isDark ? Colors.grey[400] : AppColors.textMuted,
            ),
            tooltip: 'Edit Profile',
            onPressed: () => context.push(RouteNames.profileEdit),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          children: [
            if (ref.watch(profileProvider).status == ProfileStatus.error &&
                profile == null)
              AppErrorWidget(
                message:
                    ref.watch(profileProvider).message ?? 'Could not load profile.',
                onRetry: () => ref.read(profileProvider.notifier).load(),
              )
            else ...[
              const SizedBox(height: AppDimensions.paddingMd),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primaryBlue,
                      backgroundImage: (avatarUrl?.isNotEmpty ?? false)
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: (avatarUrl?.isNotEmpty != true)
                          ? Text(
                              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.paddingSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if ((profile?.isVerified ??
                                authUser?.isVerified ??
                            false)) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              size: 20, color: AppColors.primaryBlue),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : AppColors.textMuted,
                      ),
                    ),
                    if (stats?.memberSince != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Member since ${stats!.memberSince!.formattedDate}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? Colors.grey[500] : AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              StatsCard(
                level: ranking.level,
                totalPoints: ranking.totalPoints,
                currentLevelPoints: ranking.currentLevelPoints,
                nextLevelPoints: ranking.nextLevelPoints,
                pointsToNextLevel: ranking.pointsToNextLevel,
                badge:
                    ranking.badge.isEmpty ? 'bronze' : ranking.badge,
                weeklyRank: ranking.weeklyRank,
                quizzesCompleted: ranking.quizzesCompleted,
              ),
              const SizedBox(height: AppDimensions.lg),
              Center(
                child: Text(
                  'Swipe or tap the menu icon to open your menu',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : AppColors.textLight,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
