import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/common/widgets/app_empty_state.dart';
import '../../../../core/common/widgets/app_error_widget.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/common/widgets/shimmer_widget.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/bible_study_entities.dart';
import '../providers/bible_study_provider.dart';

class ChapterNotesPage extends ConsumerStatefulWidget {
  final String book;
  final int chapter;

  const ChapterNotesPage({
    super.key,
    required this.book,
    required this.chapter,
  });

  @override
  ConsumerState<ChapterNotesPage> createState() => _ChapterNotesPageState();
}

class _ChapterNotesPageState extends ConsumerState<ChapterNotesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(chapterNotesProvider((book: widget.book, chapter: widget.chapter)).notifier)
          .load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = chapterNotesProvider((book: widget.book, chapter: widget.chapter));
    final state = ref.watch(provider);

    return AppScaffold(
      appBar: AppBar(
        title: Text('Notes · ${normalizeBookName(widget.book)} ${widget.chapter}'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isMutating
            ? null
            : () => _openEditor(book: widget.book, chapter: widget.chapter),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Add note'),
      ),
      body: _buildBody(state, ref.read(provider.notifier)),
    );
  }

  Widget _buildBody(ChapterNotesState state, ChapterNotesNotifier notifier) {
    if (state.status == BibleStudyStatus.loading ||
        state.status == BibleStudyStatus.initial) {
      return const _NotesListShimmer();
    }

    if (state.status == BibleStudyStatus.error) {
      return AppErrorWidget(
        message: state.message ?? 'Could not load notes',
        onRetry: notifier.load,
      );
    }

    if (state.notes.isEmpty) {
      return const AppEmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'No notes yet',
        subtitle: 'Tap "Add note" to capture your thoughts on this chapter.',
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.md),
        itemCount: state.notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.sm),
        itemBuilder: (context, index) {
          final note = state.notes[index];
          return _NoteCard(
            note: note,
            onEdit: () => _openEditor(
              book: widget.book,
              chapter: widget.chapter,
              note: note,
            ),
            onDelete: () => _confirmDelete(note, notifier),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(ChapterNote note, ChapterNotesNotifier notifier) async {
    final confirmed = await AlertWidget.showConfirmDialog(
      context,
      title: 'Delete note',
      message: 'Delete this note for ${note.reference}?',
      confirmLabel: 'Delete',
      type: AlertType.error,
    );
    if (confirmed == true) {
      unawaited(notifier.remove(note.id));
    }
  }

  Future<void> _openEditor({
    required String book,
    required int chapter,
    ChapterNote? note,
  }) async {
    final content = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NoteEditorSheet(
        initialContent: note?.content ?? '',
        book: book,
        chapter: chapter,
      ),
    );

    if (content == null) return;

    if (note == null) {
      unawaited(
        ref
            .read(chapterNotesProvider((book: book, chapter: chapter)).notifier)
            .add(content),
      );
    } else {
      unawaited(
        ref
            .read(chapterNotesProvider((book: book, chapter: chapter)).notifier)
            .update(note.id, content),
      );
    }
  }
}

class _NoteEditorSheet extends StatefulWidget {
  final String initialContent;
  final String book;
  final int chapter;

  const _NoteEditorSheet({
    required this.initialContent,
    required this.book,
    required this.chapter,
  });

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  static const int _maxChars = 5000;

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingLg,
          AppDimensions.paddingMd,
          AppDimensions.paddingLg,
          AppDimensions.paddingLg,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              widget.initialContent.isEmpty
                  ? 'New note'
                  : 'Edit note',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${normalizeBookName(widget.book)} ${widget.chapter} · max $_maxChars characters',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 8,
              maxLength: _maxChars,
              decoration: InputDecoration(
                hintText: 'Write your thoughts about this chapter…',
                fillColor: isDark ? const Color(0xFF0F172A) : AppColors.bgGray,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _controller.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, _controller.text.trim()),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(widget.initialContent.isEmpty ? 'Save note' : 'Update note'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final ChapterNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({required this.note, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: onEdit,
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
                  Icon(
                    Icons.sticky_note_2_rounded,
                    size: 18,
                    color: isDark ? Colors.grey[400] : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.reference,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : AppColors.textMuted,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: isDark ? Colors.grey[500] : AppColors.textLight,
                    ),
                  ),
                ],
              ),
              Text(
                note.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                ),
              ),
              if (note.updatedAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  _formatUpdated(note.updatedAt!),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[600] : AppColors.textLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatUpdated(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Updated ${diff.inDays}d ago';
    return 'Updated ${date.day}/${date.month}/${date.year}';
  }
}

class _NotesListShimmer extends StatelessWidget {
  const _NotesListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.sm),
      itemBuilder: (context, index) => const ShimmerWidget(
        width: double.infinity,
        height: 120,
        borderRadius: AppDimensions.radiusLg,
      ),
    );
  }
}