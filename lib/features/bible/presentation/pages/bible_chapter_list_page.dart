import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../providers/bible_providers.dart';

class BibleChapterListPage extends ConsumerWidget {
  final String book;

  const BibleChapterListPage({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(bibleChaptersProvider(book));

    return AppScaffold(
      appBar: AppBar(
        title: Text(book),
        centerTitle: true,
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Text(
              'Could not load chapters.\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (chapters) => _ChapterGrid(book: book, chapters: chapters),
      ),
    );
  }
}

class _ChapterGrid extends StatelessWidget {
  final String book;
  final List<int> chapters;

  const _ChapterGrid({required this.book, required this.chapters});

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return const Center(child: Text('No chapters available'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: chapters.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppDimensions.sm,
        mainAxisSpacing: AppDimensions.sm,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return _ChapterTile(
          chapter: chapter,
          onTap: () => context.pushNamed(
            RouteNames.bibleChapter,
            pathParameters: {
              'book': Uri.encodeComponent(book),
              'chapter': chapter.toString(),
            },
          ),
        );
      },
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final int chapter;
  final VoidCallback onTap;

  const _ChapterTile({required this.chapter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
          ),
          child: Center(
            child: Text(
              '$chapter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}