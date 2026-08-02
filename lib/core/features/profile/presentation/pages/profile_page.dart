import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/widgets/stats_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          const SizedBox(height: AppDimensions.paddingMd),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    user != null && user.fullName.isNotEmpty
                        ? user.fullName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingSm),
                Text(
                  user?.fullName ?? 'User',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'user@example.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          const StatsCard(
            level: 3,
            totalPoints: 1250,
            currentLevelPoints: 250,
            nextLevelPoints: 500,
            pointsToNextLevel: 250,
            badge: 'bronze',
            weeklyRank: 12,
            quizzesCompleted: 8,
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
      ),
    );
  }
}