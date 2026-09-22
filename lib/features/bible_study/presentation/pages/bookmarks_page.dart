import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/common/widgets/app_empty_state.dart';
import '../../../../core/common/widgets/app_error_widget.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/common/widgets/shimmer_widget.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/bible_study_entities.dart';
import '../providers/bible_study_provider.dart';

class BookmarksPage extends ConsumerStatefulWidget {
  const BookmarksPage({super.key});

  @override
  ConsumerState<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends ConsumerState<BookmarksPage> with RouteAware {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(bookmarksProvider).status == BibleStudyStatus.initial) {
        ref.read(bookmarksProvider.notifier).load();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    ref.read(bookmarksProvider.notifier).load();
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookmarksProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        centerTitle: true,
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(BookmarksState state) {
    if (state.status == BibleStudyStatus.loading ||
        state.status == BibleStudyStatus.initial) {
      return const _BookmarkListShimmer();
    }

    if (state.status == BibleStudyStatus.error) {
      return AppErrorWidget(
        message: state.message ?? 'Could not load bookmarks',
        onRetry: () => ref.read(bookmarksProvider.notifier).load(),
      );
    }

    if (state.bookmarks.isEmpty) {
      return AppEmptyState(
        icon: Icons.bookmark_outline,
        title: 'No bookmarks yet',
        subtitle: 'Bookmark verses or chapters while reading the Bible.',
        actionLabel: 'Open Bible',
        onAction: () => context.pushNamed(RouteNames.bibleReader),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(bookmarksProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.md),
        itemCount: state.bookmarks.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.sm),
        itemBuilder: (context, index) => BookmarkTile(
          bookmark: state.bookmarks[index],
          onDelete: () => _confirmDelete(context, state.bookmarks[index]),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Bookmark bookmark) async {
    final confirmed = await AlertWidget.showConfirmDialog(
      context,
      title: 'Remove bookmark',
      message: 'Remove ${bookmark.reference} from your bookmarks?',
      confirmLabel: 'Remove',
    );
    if (confirmed == true) {
      unawaited(ref.read(bookmarksProvider.notifier).remove(bookmark.id));
    }
  }
}

class BookmarkTile extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback? onDelete;

  const BookmarkTile({super.key, required this.bookmark, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: () => _goToBookmark(context),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(
                  bookmark.isChapterBookmark
                      ? Icons.bookmarks_rounded
                      : Icons.bookmark_rounded,
                  color: AppColors.primaryAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark.reference,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bookmark.isChapterBookmark ? 'Chapter' : 'Verse',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : AppColors.textLight,
                      ),
                    ),
                    if (bookmark.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        bookmark.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark ? Colors.grey[300] : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: isDark ? Colors.grey[500] : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToBookmark(BuildContext context) {
    if (bookmark.verse == null) {
      context.pushNamed(
        RouteNames.bibleChapter,
        pathParameters: {
          'book': bookmark.bookName,
          'chapter': bookmark.chapter.toString(),
        },
      );
    } else {
      context.pushNamed(
        RouteNames.bibleVerseDetail,
        pathParameters: {
          'book': bookmark.bookName,
          'chapter': bookmark.chapter.toString(),
          'verse': bookmark.verse.toString(),
        },
      );
    }
  }
}

class _BookmarkListShimmer extends StatelessWidget {
  const _BookmarkListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.sm),
      itemBuilder: (context, index) => const ShimmerWidget(
        width: double.infinity,
        height: 74,
        borderRadius: AppDimensions.radiusLg,
      ),
    );
  }
}