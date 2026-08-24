import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../providers/course_providers.dart';
import '../widgets/course_card.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Courses')),
      backgroundColor: AppColors.bgGray,
      body: const SafeArea(child: CoursesGridBody()),
    );
  }
}

class CoursesGridBody extends ConsumerStatefulWidget {
  final bool showFilters;

  const CoursesGridBody({super.key, this.showFilters = true});

  @override
  ConsumerState<CoursesGridBody> createState() => _CoursesGridBodyState();
}

class _CoursesGridBodyState extends ConsumerState<CoursesGridBody>
    with AutomaticKeepAliveClientMixin {
  static const _difficulties = [
    (label: 'All', value: null),
    (label: 'Easy', value: 'easy'),
    (label: 'Medium', value: 'medium'),
    (label: 'Hard', value: 'hard'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(coursesProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(coursesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        if (widget.showFilters) _buildFilters(isDark),
        Expanded(child: _buildGrid(context, state, isDark)),
      ],
    );
  }

  Widget _buildFilters(bool isDark) {
    final active = ref.watch(coursesProvider).difficulty;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.sm,
        ),
        children: _difficulties.map((difficulty) {
          final selected = difficulty.value == active;
          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.sm),
            child: ChoiceChip(
              label: Text(difficulty.label),
              selected: selected,
              onSelected: (_) =>
                  ref.read(coursesProvider.notifier).setDifficulty(
                        difficulty.value,
                      ),
              selectedColor: AppColors.primaryBlue,
              backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : AppColors.textSecondary),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    CoursesState state,
    bool isDark,
  ) {
    if (state.status == CoursesStatus.loading && state.courses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CoursesStatus.error && state.courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: isDark ? Colors.grey[600] : AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Text(
              state.message ?? 'Could not load courses',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            TextButton.icon(
              onPressed: () => ref.read(coursesProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_rounded,
              size: 64,
              color: isDark ? Colors.grey[600] : AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Text(
              'No courses available yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              'Structured learning paths are on the way',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[500] : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(coursesProvider.notifier).refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingMd,
          AppDimensions.sm,
          AppDimensions.paddingMd,
          AppDimensions.paddingXl,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppDimensions.paddingMd,
          crossAxisSpacing: AppDimensions.paddingMd,
          mainAxisExtent: 236,
        ),
        itemCount: state.courses.length,
        itemBuilder: (context, index) {
          final course = state.courses[index];
          return CourseCard(
            course: course,
            onTap: () async {
              await context.push(RouteNames.courseDetail, extra: course.id);
              if (context.mounted) {
                await ref.read(coursesProvider.notifier).refresh();
              }
            },
          );
        },
      ),
    );
  }
}

