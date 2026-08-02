import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../router/route_names.dart';
import '../../../../../features/quiz/presentation/providers/quiz_provider.dart';
import '../../../../../features/quiz/domain/entities/quiz_entities.dart';

class QuizHomePage extends ConsumerStatefulWidget {
  const QuizHomePage({super.key});

  @override
  ConsumerState<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends ConsumerState<QuizHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(quizProvider.notifier).loadUpcomingQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Quizzes')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(quizProvider.notifier).loadUpcomingQuizzes();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingXl),
          children: [
            const SizedBox(height: AppDimensions.sm),
            _buildSectionTitle(context, 'Quizzes', isDark),
            const SizedBox(height: AppDimensions.sm),
            _buildQuizzes(context, quizState, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildQuizzes(BuildContext context, QuizState quizState, bool isDark) {
    final quizzes = quizState.upcomingQuizzes;

    if (quizState.status == QuizStatus.loading && quizzes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (quizzes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.xl),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
          ),
          child: Center(
            child: Text(
              quizState.message ?? 'No quizzes available right now',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : AppColors.textLight,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: quizzes.map((quiz) {
        return _QuizCard(quiz: quiz);
      }).toList(),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final QuizSchedule quiz;

  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _isActive(quiz);
    final dateLabel = _dateLabel(quiz);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMd,
        0,
        AppDimensions.paddingMd,
        AppDimensions.paddingSm,
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          onTap: () => context.push(RouteNames.quizDetail, extra: quiz.id),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: isActive
                    ? AppColors.success.withValues(alpha: 0.4)
                    : (isDark ? const Color(0xFF334155) : AppColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppDimensions.paddingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryAmber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Row(
                        children: [
                          const Icon(Icons.help_outline_rounded, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${quiz.totalQuestions} questions',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[500] : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          const Icon(Icons.timer_outlined, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${quiz.durationMinutes}m',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[500] : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: AppDimensions.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.successBg
                        : AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Scheduled',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.success : AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isActive(QuizSchedule quiz) {
    final now = DateTime.now();
    return !now.isAfter(quiz.endDateTime) && !now.isBefore(quiz.startDateTime);
  }

  String _dateLabel(QuizSchedule quiz) {
    final now = DateTime.now();
    final sameDay = now.year == quiz.startDateTime.year &&
        now.month == quiz.startDateTime.month &&
        now.day == quiz.startDateTime.day;
    if (sameDay) {
      return 'Today · ${DateFormat('h:mm a').format(quiz.startDateTime)}';
    }
    return DateFormat('MMM d, h:mm a').format(quiz.startDateTime);
  }
}