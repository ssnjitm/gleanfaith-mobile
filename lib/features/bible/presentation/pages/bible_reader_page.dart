import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/bible_book.dart';
import '../providers/bible_providers.dart';

class BibleReaderPage extends ConsumerWidget {
  const BibleReaderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bibleBooksProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Bible'),
        centerTitle: true,
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Text(
              'Could not load the Bible.\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (books) => _BookList(books: books),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  final List<BibleBook> books;

  const _BookList({required this.books});

  @override
  Widget build(BuildContext context) {
    final oldTestament = books.where((b) => b.isOldTestament).toList();
    final newTestament = books.where((b) => !b.isOldTestament).toList();

    if (oldTestament.isEmpty && newTestament.isEmpty) {
      return const Center(child: Text('No books available'));
    }

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.md),
      children: [
        if (oldTestament.isNotEmpty) ...[
          _SectionHeader(title: 'Old Testament', count: oldTestament.length),
          const SizedBox(height: AppDimensions.sm),
          _BookGrid(books: oldTestament),
        ],
        const SizedBox(height: AppDimensions.lg),
        if (newTestament.isNotEmpty) ...[
          _SectionHeader(title: 'New Testament', count: newTestament.length),
          const SizedBox(height: AppDimensions.sm),
          _BookGrid(books: newTestament),
        ],
        const SizedBox(height: AppDimensions.lg),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppDimensions.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookGrid extends StatelessWidget {
  final List<BibleBook> books;

  const _BookGrid({required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppDimensions.sm,
        mainAxisSpacing: AppDimensions.sm,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final book = books[index];
        return _BookTile(
          book: book,
          onTap: () => context.pushNamed(
            RouteNames.bibleChapters,
            pathParameters: {'book': Uri.encodeComponent(book.name)},
          ),
        );
      },
    );
  }
}

class _BookTile extends StatelessWidget {
  final BibleBook book;
  final VoidCallback onTap;

  const _BookTile({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                book.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                '${book.chapterCount} ch.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}