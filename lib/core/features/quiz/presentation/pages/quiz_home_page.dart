import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';

class QuizHomePage extends ConsumerWidget {
  const QuizHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Quizzes')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_rounded,
              size: 64,
              color: isDark ? Colors.grey[600] : AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Text(
              'Quizzes Coming Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSm),
            Text(
              'Your quiz journey awaits',
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
