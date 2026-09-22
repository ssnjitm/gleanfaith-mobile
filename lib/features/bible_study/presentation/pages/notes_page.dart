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

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> with RouteAware {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(notesProvider).status == BibleStudyStatus.initial) {
        ref.read(notesProvider.notifier).load();
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
    ref.read(notesProvider.notifier).load();
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Chapter Notes'),
        centerTitle: true,
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotesState state) {
    if (state.status == BibleStudyStatus.loading ||
        state.status == BibleStudyStatus.initial) {
      return const _NotesShimmer();
    }

    if (state.status == BibleStudyStatus.error) {
      return AppErrorWidget(
        message: state.message ?? 'Could not load notes',
        onRetry: () => ref.read(notesProvider.notifier).load(),
      );
    }

    if (state.notes.isEmpty) {
      return const AppEmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'No notes yet',
        subtitle: 'Write chapter notes while reading to see them here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notesProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.md),
        itemCount: state.notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.sm),
        itemBuilder: (context, index) {
          final note = state.notes[index];
          return _NoteListTile(
            note: note,
            onTap: () => context.pushNamed(
              RouteNames.bibleChapterNotes,
              pathParameters: {
                'book': note.bookName,
                'chapter': note.chapter.toString(),
              },
            ),
            onDelete: () => _confirmDelete(note),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(ChapterNote note) async {
    final confirmed = await AlertWidget.showConfirmDialog(
      context,
      title: 'Delete note',
      message: 'Delete this note for ${note.reference}?',
      confirmLabel: 'Delete',
      type: AlertType.error,
    );
    if (confirmed == true) {
      unawaited(ref.read(notesProvider.notifier).remove(note.id));
    }
  }
}

class _NoteListTile extends StatelessWidget {
  final ChapterNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteListTile({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
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
                          note.reference,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        if (note.updatedAt != null)
                          Text(
                            _formatDate(note.updatedAt!),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : AppColors.textLight,
                            ),
                          ),
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
              const SizedBox(height: AppDimensions.sm),
              Text(
                note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NotesShimmer extends StatelessWidget {
  const _NotesShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.sm),
      itemBuilder: (context, index) => const ShimmerWidget(
        width: double.infinity,
        height: 110,
        borderRadius: AppDimensions.radiusLg,
      ),
    );
  }
}