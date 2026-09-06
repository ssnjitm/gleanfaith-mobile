import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/shimmer_widget.dart';
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

    final embedded = _args.embedded;
    if (embedded != null && embedded.isRenderable) {
      setState(() {
        _loading = false;
        _doc = embedded;
      });
      return;
    }

    setState(() => _loading = true);
    final result =
        await ref.read(getCourseContentUseCaseProvider).call(_args.refId).run();
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = embedded != null
                ? 'This material may not be published yet.'
                : failure.message;
            _doc = embedded;
          });
        }
      },
      (doc) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = null;
            _doc = doc;
          });
        }
      },
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
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingLg,
          AppDimensions.paddingMd,
          AppDimensions.paddingLg,
          AppDimensions.paddingXl,
        ),
        children: const [
          ShimmerWidget(
            width: double.infinity,
            height: 36,
            borderRadius: AppDimensions.radiusSm,
          ),
          SizedBox(height: AppDimensions.paddingSm),
          ShimmerWidget(
            width: 90,
            height: 14,
            borderRadius: AppDimensions.radiusSm,
          ),
          SizedBox(height: AppDimensions.paddingMd),
          ShimmerWidget(
            width: double.infinity,
            height: 320,
            borderRadius: AppDimensions.radiusLg,
          ),
          SizedBox(height: AppDimensions.paddingLg),
          ShimmerTextLine(width: 1.0),
          SizedBox(height: AppDimensions.xs),
          ShimmerTextLine(width: 0.92),
          SizedBox(height: AppDimensions.xs),
          ShimmerTextLine(width: 0.6),
        ],
      );
    }

    final doc = _doc;

    if (doc == null) {
      return _buildUnpublishedFallback(isDark);
    }

    if (_error != null && !doc.isRenderable) {
      return _buildUnpublishedFallback(isDark);
    }

    final hasMedia =
        doc.type == 'video' || doc.type == 'audio' || doc.type == 'pdf';

    if (hasMedia && (doc.fileUrl == null || doc.fileUrl!.isEmpty) &&
        (doc.videoUrl == null || doc.videoUrl!.isEmpty)) {
      return _buildUnpublishedFallback(isDark);
    }

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

  Widget _buildUnpublishedFallback(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 56,
              color: isDark ? Colors.white24 : AppColors.textMuted,
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Text(
              'Content not available yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'This material may still be unpublished. You can mark this step as complete and check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white54 : AppColors.textMuted,
              ),
            ),
          ],
        ),
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
