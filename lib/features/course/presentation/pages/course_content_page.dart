import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/app_error_widget.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../library/presentation/widgets/library_content_player.dart';
import '../../domain/entities/course_entities.dart';
import '../../domain/entities/course_progress_entities.dart';
import '../providers/course_detail_provider.dart';
import '../providers/course_providers.dart';

class CourseContentPage extends ConsumerStatefulWidget {
  final CourseContentViewArgs? args;

  const CourseContentPage({super.key, required this.args});

  @override
  ConsumerState<CourseContentPage> createState() => _CourseContentPageState();
}

class _CourseContentPageState extends ConsumerState<CourseContentPage> {
  bool _loading = true;
  String? _error;
  CourseContentDocument? _doc;

  CourseContentViewArgs get _args =>
      widget.args ??
      const CourseContentViewArgs(
        courseId: '',
        itemId: '',
        refId: '',
        alreadyCompleted: false,
      );

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (widget.args == null || _args.refId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing content reference.';
      });
      return;
    }
    setState(() => _loading = true);
    final result =
        await ref.read(getCourseContentUseCaseProvider).call(_args.refId).run();
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (doc) => setState(() {
        _loading = false;
        _error = null;
        _doc = doc;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        title: Text(_typeLabel),
        actions: [
          if (_args.alreadyCompleted)
            const Padding(
              padding: EdgeInsets.only(right: AppDimensions.paddingMd),
              child: Center(
                child: Icon(Icons.check_circle_rounded,
                    color: AppColors.success),
              ),
            ),
        ],
      ),
      body: _buildBody(isDark),
      bottomNavigationBar:
          widget.args == null ? null : _buildCompleteBar(isDark),
    );
  }

  String get _typeLabel {
    switch (_doc?.type ?? '') {
      case 'video':
        return 'Video Lesson';
      case 'audio':
        return 'Audio Lesson';
      case 'pdf':
        return 'PDF Document';
      default:
        return 'Lesson';
    }
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _doc == null) {
      return AppErrorWidget(
        message: _error ?? 'Could not load this lesson content.',
        onRetry: () => Future.microtask(_load),
      );
    }

    final doc = _doc!;
    final hasMedia =
        doc.type == 'video' || doc.type == 'audio' || doc.type == 'pdf';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLg,
        AppDimensions.paddingMd,
        AppDimensions.paddingLg,
        AppDimensions.paddingXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doc.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          if (doc.readTimeMinutes != null) ...[
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: isDark ? Colors.grey[400] : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${doc.readTimeMinutes} min',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey[400] : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppDimensions.paddingMd),
          if (hasMedia)
            LibraryContentPlayer(
              key: ValueKey(doc.id),
              type: doc.type,
              videoUrl: doc.videoUrl ?? doc.fileUrl,
              audioUrl: doc.fileUrl ?? doc.videoUrl,
              pdfUrl: doc.fileUrl ?? doc.videoUrl,
              thumbnailUrl: doc.thumbnailUrl,
              body: doc.body,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color:
                      isDark ? const Color(0xFF334155) : AppColors.borderLight,
                ),
              ),
              child: Text(
                doc.body.isEmpty
                    ? 'No content available for this lesson yet.'
                    : doc.body,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: isDark ? Colors.grey[200] : AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompleteBar(bool isDark) {
    if (_args.courseId.isEmpty ||
        _args.itemId.isEmpty ||
        _args.alreadyCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.paddingLg,
        AppDimensions.paddingSm + 2,
        AppDimensions.paddingLg,
        AppDimensions.paddingSm + 2 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgWhite,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppDimensions.buttonHeight,
        child: ElevatedButton.icon(
          onPressed: ref
                  .watch(courseDetailProvider(_args.courseId))
                  .working
              ? null
              : _markComplete,
          icon: ref.watch(courseDetailProvider(_args.courseId)).working
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: Text(
            ref.watch(courseDetailProvider(_args.courseId)).working
                ? 'Saving...'
                : 'Mark as Complete',
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Future<void> _markComplete() async {
    final result = await ref
        .read(courseDetailProvider(_args.courseId).notifier)
        .completeItem(_args.itemId);
    if (!mounted) return;
    context.pop(result);
  }
}
