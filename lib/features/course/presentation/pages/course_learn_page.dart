import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/common/widgets/app_error_widget.dart';
import '../../../../core/common/widgets/content_thumbnail.dart';
import '../../../../core/common/widgets/shimmer_placeholders.dart';
import '../../../../core/common/widgets/shimmer_widget.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/course_entities.dart';
import '../../domain/entities/course_progress_entities.dart';
import '../providers/course_detail_provider.dart';
import '../providers/course_quiz_attempts.dart';

class CourseLearnPage extends ConsumerStatefulWidget {
  final String courseId;

  const CourseLearnPage({super.key, required this.courseId});

  @override
  ConsumerState<CourseLearnPage> createState() => _CourseLearnPageState();
}

class _CourseLearnPageState extends ConsumerState<CourseLearnPage> {
  final Set<String> _expandedLessonIds = {};

  CourseDetailNotifier get _notifier =>
      ref.read(courseDetailProvider(widget.courseId).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courseDetailProvider(widget.courseId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(courseDetailProvider(widget.courseId), (prev, next) {
      final message = next.message;
      if (message != null && message != prev?.message) {
        AlertWidget.showError(context, message);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        title: Text(
          state.detail?.title ?? 'Course',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (state.detail != null && state.detail!.isStarted)
            IconButton(
              tooltip: 'Reset progress',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: state.working ? null : _confirmReset,
            ),
        ],
      ),
      body: _buildBody(state, isDark),
    );
  }

  Widget _buildBody(CourseDetailState state, bool isDark) {
    switch (state.phase) {
      case CourseDetailPhase.loading:
        return ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          children: const [
            ShimmerWidget(width: double.infinity, height: 150, borderRadius: AppDimensions.radiusXl),
            SizedBox(height: AppDimensions.paddingMd),
            ShimmerWidget(width: double.infinity, height: 60, borderRadius: AppDimensions.radiusLg),
            SizedBox(height: AppDimensions.paddingMd),
            CourseCardShimmer(),
            SizedBox(height: AppDimensions.paddingMd),
            CourseCardShimmer(),
          ],
        );
      case CourseDetailPhase.error:
        return AppErrorWidget(
          message: state.message ?? 'Could not load this course',
          onRetry: _notifier.load,
        );
      case CourseDetailPhase.ready:
        final detail = state.detail!;
        final progress = state.progress;
        final completedIds =
            progress?.completedItemIds ?? detail.completedItemIds;

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _notifier.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingMd,
                  AppDimensions.paddingMd,
                  AppDimensions.paddingMd,
                  AppDimensions.paddingXl,
                ),
                children: [
                  _buildBanner(detail, isDark),
                  const SizedBox(height: AppDimensions.paddingMd),
                  if (detail.description.isNotEmpty) ...[
                    Text(
                      detail.description,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color:
                            isDark ? Colors.grey[300] : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                  ],
                  _buildStatsRow(detail, isDark),
                  const SizedBox(height: AppDimensions.paddingMd),
                  _buildProgressCard(state, isDark),
                  const SizedBox(height: AppDimensions.paddingLg),
                  ...detail.lessons.map(
                    (lesson) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.paddingMd),
                      child: _buildLessonCard(
                        state,
                        lesson,
                        completedIds,
                        isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (state.working)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        );
    }
  }

  Widget _buildBanner(CourseDetail detail, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: SizedBox(
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (detail.thumbnail != null && detail.thumbnail!.isNotEmpty)
              Image.network(
                detail.thumbnail!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _bannerFallback(),
              )
            else
              _bannerFallback(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
                child: Wrap(
                  spacing: AppDimensions.sm,
                  runSpacing: AppDimensions.xs,
                  children: [
                    _bannerChip(
                      label: detail.difficulty.toUpperCase(),
                      color: _difficultyColor(detail.difficulty),
                    ),
                    _bannerChip(
                      label: '+${detail.points} XP',
                      color: AppColors.primaryAmber,
                    ),
                    if (detail.categoryName != null)
                      _bannerChip(
                        label: detail.categoryName!,
                        color: AppColors.primaryBlue,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerFallback() {
    return Container(
      color: AppColors.primaryBlue.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        Icons.auto_stories_rounded,
        size: 48,
        color: AppColors.primaryBlue.withValues(alpha: 0.45),
      ),
    );
  }

  Widget _bannerChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildStatsRow(CourseDetail detail, bool isDark) {
    return Row(
      children: [
        _statCell(
          icon: Icons.layers_rounded,
          value: '${detail.stats.totalLessons}',
          label: 'Lessons',
          isDark: isDark,
        ),
        const SizedBox(width: AppDimensions.sm),
        _statCell(
          icon: Icons.checklist_rounded,
          value: '${detail.stats.totalItems}',
          label: 'Steps',
          isDark: isDark,
        ),
        const SizedBox(width: AppDimensions.sm),
        _statCell(
          icon: Icons.emoji_events_outlined,
          value: '${detail.totalCompletions}',
          label: 'Completed',
          isDark: isDark,
        ),
        if (detail.estimatedDurationMinutes != null) ...[
          const SizedBox(width: AppDimensions.sm),
          _statCell(
            icon: Icons.schedule_rounded,
            value: '${detail.estimatedDurationMinutes}m',
            label: 'Est. time',
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _statCell({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm + 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryBlue),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[500] : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(CourseDetailState state, bool isDark) {
    final detail = state.detail!;
    final progress = state.progress;

    if (!detail.isStarted && progress == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Ready to learn?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              'Start this course to track your progress and earn ${detail.points} XP.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            _gradientButton(
              label: 'Start Course',
              icon: Icons.play_arrow_rounded,
              onPressed: state.working ? null : _notifier.startCourse,
            ),
          ],
        ),
      );
    }

    final completed = progress?.completedItemsCount ??
        (detail.isCompleted ? detail.stats.totalItems : detail.completedItemIds.length);
    final total = progress?.totalItems ?? detail.stats.totalItems;
    final fraction = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final isDone = progress?.status == 'completed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDone
              ? AppColors.success.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF334155) : AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isDone ? 'Completed' : 'Your progress',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDone
                      ? AppColors.success
                      : (isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
              const Spacer(),
              Text(
                '${(fraction * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDone
                      ? AppColors.success
                      : AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor:
                  (isDark ? Colors.grey[700] : AppColors.borderLight)
                      ?.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? AppColors.success : AppColors.primaryAmber,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            progress != null
                ? '$completed of $total steps · '
                    '${progress.completedLessons}/${progress.totalLessons} lessons'
                : '$completed of $total steps done',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.grey[400] : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(
    CourseDetailState state,
    CourseLesson lesson,
    Set<String> completedIds,
    bool isDark,
  ) {
    final progress = state.progress;
    LessonProgress? lessonProgress;
    final lessons = progress?.lessons ?? const <LessonProgress>[];
    for (final l in lessons) {
      if (l.lessonId == lesson.id) {
        lessonProgress = l;
        break;
      }
    }

    final LessonStatusInfo status;
    if (lessonProgress != null) {
      status = LessonStatusInfo.fromStatus(lessonProgress.status);
    } else {
      final doneCount =
          lesson.items.where((i) => completedIds.contains(i.itemId)).length;
      status = LessonStatusInfo.compute(doneCount, lesson.items.length);
    }

    final expanded = _expandedLessonIds.contains(lesson.id);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              onTap: () => setState(() {
                if (expanded) {
                  _expandedLessonIds.remove(lesson.id);
                } else {
                  _expandedLessonIds.add(lesson.id);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                child: Row(
                  children: [
                    _lessonStatusDot(status),
                    const SizedBox(width: AppDimensions.paddingSm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lesson.order}. ${lesson.title}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${status.doneCount}/${lesson.items.length} steps · ${_lessonTypeSummary(lesson)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? Colors.grey[400]
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color:
                            isDark ? Colors.grey[400] : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingSm + 2),
              child: Column(
                children: [
                  if (lesson.items.isNotEmpty)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppDimensions.sm,
                      crossAxisSpacing: AppDimensions.sm,
                      childAspectRatio: 0.78,
                      children: lesson.items.map((item) {
                        return _buildItemGridCard(
                          lesson,
                          item,
                          completedIds.contains(item.itemId),
                          progress?.resultForItem(item.itemId),
                          isDark,
                        );
                      }).toList(),
                    ),
                  if (_canCompleteWholeLesson(lesson, completedIds))
                    Padding(
                      padding: const EdgeInsets.only(top: AppDimensions.xs),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: state.working
                              ? null
                              : () => _completeLesson(lesson.id),
                          icon: const Icon(Icons.done_all_rounded, size: 18),
                          label: const Text('Mark lesson complete'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lessonStatusDot(LessonStatusInfo status) {
    final color = switch (status.kind) {
      LessonStatusKind.completed => AppColors.success,
      LessonStatusKind.inProgress => AppColors.warning,
      LessonStatusKind.notStarted =>
        AppColors.textLight.withValues(alpha: 0.5),
    };
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(status.kind == LessonStatusKind.completed
          ? Icons.check_rounded
          : Icons.circle,
          size: status.kind == LessonStatusKind.completed ? 16 : 6,
          color: color),
    );
  }

  String _lessonTypeSummary(CourseLesson lesson) {
    final quizzes =
        lesson.items.where((i) => i.isQuiz).length;
    final contents = lesson.items.length - quizzes;
    final parts = <String>[
      if (contents > 0) '$contents content',
      if (quizzes > 0) '$quizzes quiz',
    ];
    return parts.join(' · ');
  }

  bool _canCompleteWholeLesson(
    CourseLesson lesson,
    Set<String> completedIds,
  ) {
    if (lesson.items.isEmpty) return false;
    final allContent = lesson.items.every((i) => !i.isQuiz);
    final allDone = lesson.items.every((i) => completedIds.contains(i.itemId));
    return allContent && !allDone;
  }

  Widget _buildItemGridCard(
    CourseLesson lesson,
    CourseLessonItem item,
    bool completed,
    CourseQuizResult? previousResult,
    bool isDark,
  ) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openItem(lesson, item, completed),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.isQuiz)
                    _quizThumb(item, isDark)
                  else
                    ContentThumbnail(
                      type: item.displayType,
                      thumbnailUrl: item.content?.thumbnailUrl,
                      iconSize: 34,
                    ),
                  if (completed)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.isQuiz ? 'Quiz' : _itemTypeLabel(item),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.sm + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _itemSubtitle(item, previousResult),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.grey[400] : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quizThumb(CourseLessonItem item, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryAmber.withValues(alpha: 0.85),
            AppColors.primaryAmber.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.quiz_rounded, size: 34, color: Colors.white),
      ),
    );
  }

  String _itemTypeLabel(CourseLessonItem item) {
    switch (item.displayType) {
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'pdf':
        return 'PDF';
      default:
        return 'Article';
    }
  }

  String _itemSubtitle(CourseLessonItem item, CourseQuizResult? result) {
    if (item.isQuiz) {
      final buffer = StringBuffer();
      buffer.write(
        item.quiz?.questionCount != null
            ? '${item.quiz!.questionCount} questions'
            : 'Quiz',
      );
      if (result != null) {
        buffer.write(
          ' · Best ${result.percentage.round()}%'
          ' (${result.attempts} attempt${result.attempts == 1 ? '' : 's'})',
        );
      }
      return buffer.toString();
    }
    final typeLabel = switch (item.displayType) {
      'video' => 'Video',
      'audio' => 'Audio',
      'pdf' => 'PDF document',
      _ => 'Article',
    };
    final minutes = item.content?.readTimeMinutes;
    return minutes != null ? '$typeLabel · $minutes min' : typeLabel;
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'hard':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.buttonHeight / 2),
          onTap: onPressed,
          child: Ink(
            height: AppDimensions.buttonHeight,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius:
                  BorderRadius.circular(AppDimensions.buttonHeight / 2),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: AppDimensions.xs),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openItem(
    CourseLesson lesson,
    CourseLessonItem item,
    bool completed) async {
    if (ref.read(courseDetailProvider(widget.courseId)).progress == null) {
      await _notifier.startCourse();
      if (!mounted) return;
    }

    final lessonContentArgs = _lessonContentArgs(lesson, completedIds());

    if (item.isQuiz) {
      final best = await ref
          .read(courseQuizAttemptsProvider.notifier)
          .bestFor(item.itemId);
      if (!mounted) return;

      if (best != null && best.answeredCount > 0) {
        final reviewArgs = CourseQuizReviewArgs(
          courseId: widget.courseId,
          itemId: item.itemId,
          refId: item.refId,
          title: item.title,
          lessonContentArgs: lessonContentArgs,
        );
        final result = await context.push<Object?>(
          RouteNames.courseQuizReview,
          extra: reviewArgs,
        );
        if (result is CompleteCourseItemResult) {
          await _handleCompletion(result);
        }
        return;
      }

      final args = CourseQuizPlayArgs(
        courseId: widget.courseId,
        itemId: item.itemId,
        refId: item.refId,
        title: item.title,
        attemptsBefore:
            ref.read(courseDetailProvider(widget.courseId)).progress
                ?.resultForItem(item.itemId)
                ?.attempts ??
            0,
        lessonContentArgs: lessonContentArgs,
      );
      final result = await context.push<Object?>(
        RouteNames.courseQuizPlay,
        extra: args,
      );
      if (result is CompleteCourseItemResult) {
        await _handleCompletion(result);
      }
      return;
    }

    final embedded = item.content != null && item.content!.isRenderable
        ? item.content!.toDocument()
        : null;
    final args = CourseContentViewArgs(
      courseId: widget.courseId,
      itemId: item.itemId,
      refId: item.refId,
      alreadyCompleted: completed,
      embedded: embedded,
    );
    final result = await context.push<Object?>(
      RouteNames.courseContent,
      extra: args,
    );
    if (result is CompleteCourseItemResult) {
      await _handleCompletion(result);
    }
  }

  Set<String> completedIds() {
    final state = ref.read(courseDetailProvider(widget.courseId));
    return state.progress?.completedItemIds ?? state.detail?.completedItemIds ?? {};
  }

  CourseContentViewArgs? _lessonContentArgs(
    CourseLesson lesson,
    Set<String> completedIds,
  ) {
    for (final item in lesson.items) {
      if (item.isQuiz) continue;
      final embedded = item.content != null && item.content!.isRenderable
          ? item.content!.toDocument()
          : null;
      return CourseContentViewArgs(
        courseId: widget.courseId,
        itemId: item.itemId,
        refId: item.refId,
        alreadyCompleted: completedIds.contains(item.itemId),
        embedded: embedded,
      );
    }
    return null;
  }

  Future<void> _completeLesson(String lessonId) async {
    final result = await _notifier.completeLesson(lessonId);
    await _handleCompletion(result);
  }

  Future<void> _handleCompletion(CompleteCourseItemResult? result) async {
    if (result == null) return;
    if (!mounted) return;

    if (result.courseCompleted) {
      await _showCelebration(result);
    } else {
      AlertWidget.showSuccess(context, 'Step completed!');
    }
  }

  Future<void> _showCelebration(CompleteCourseItemResult result) {
    final level = result.level;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return Dialog(
          backgroundColor:
              isDark ? const Color(0xFF1E293B) : AppColors.bgWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMd),
                const Text(
                  'Course Completed!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  result.newlyAwarded
                      ? 'You finished every step and earned new XP.'
                      : 'You finished every step. Great revision!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                if (result.newlyAwarded) ...[
                  const SizedBox(height: AppDimensions.paddingMd),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMd,
                      vertical: AppDimensions.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: AppColors.primaryAmber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '+${result.pointsEarned} XP earned',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (level != null) ...[
                  const SizedBox(height: AppDimensions.paddingMd),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.paddingMd),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.06),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Level ${level.level}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${level.totalPoints} total points · '
                          '${level.pointsToNextLevel} to next level',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.paddingLg),
                SizedBox(
                  width: double.infinity,
                  child: _gradientButton(
                    label: 'Awesome',
                    icon: Icons.celebration_rounded,
                    onPressed: () => dialogContext.pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await AlertWidget.showConfirmDialog(
      context,
      title: 'Reset Progress',
      message:
          'This clears your progress on this course. XP you already earned is kept. Continue?',
      confirmLabel: 'Reset',
      type: AlertType.warning,
    );
    if (confirmed == true) {
      await _notifier.reset();
    }
  }
}

enum LessonStatusKind { notStarted, inProgress, completed }

class LessonStatusInfo {
  final LessonStatusKind kind;
  final int doneCount;

  const LessonStatusInfo({required this.kind, required this.doneCount});

  factory LessonStatusInfo.fromStatus(String status) {
    switch (status) {
      case 'completed':
        return const LessonStatusInfo(
            kind: LessonStatusKind.completed, doneCount: 0);
      case 'in_progress':
        return const LessonStatusInfo(
            kind: LessonStatusKind.inProgress, doneCount: 0);
      default:
        return const LessonStatusInfo(
            kind: LessonStatusKind.notStarted, doneCount: 0);
    }
  }

  factory LessonStatusInfo.compute(int done, int total) {
    if (total > 0 && done >= total) {
      return LessonStatusInfo(kind: LessonStatusKind.completed, doneCount: done);
    }
    if (done > 0) {
      return LessonStatusInfo(
          kind: LessonStatusKind.inProgress, doneCount: done);
    }
    return const LessonStatusInfo(
        kind: LessonStatusKind.notStarted, doneCount: 0);
  }
}
