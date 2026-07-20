import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';

class LeaderboardHomePage extends ConsumerWidget {
  const LeaderboardHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_rounded,
              size: 64,
              color: isDark ? Colors.grey[600] : AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Text(
              'Leaderboard Coming Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSm),
            Text(
              'Compete and climb the ranks',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
