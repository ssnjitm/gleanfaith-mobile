import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/content_item.dart';
import '../widgets/library_content_player.dart';

class LibraryDetailPage extends ConsumerWidget {
  final ContentItem item;

  const LibraryDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = item.type;

    return Scaffold(
      appBar: AppBar(title: Text(_typeLabel(type))),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingLg,
                AppDimensions.paddingMd,
                AppDimensions.paddingLg,
                AppDimensions.paddingXl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(context),
                  const SizedBox(height: AppDimensions.paddingMd),
                  if (_hasMedia(type))
                    _buildPlayer(context, type)
                  else
                    _buildBody(context, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasMedia(String type) {
    return type == 'video' || type == 'audio' || type == 'pdf';
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        Row(
          children: [
            _metaChip(
              icon: Icons.schedule_rounded,
              label: item.readTimeMinutes != null
                  ? '${item.readTimeMinutes} min'
                  : 'On demand',
            ),
            if (item.bibleBook != null) ...[
              const SizedBox(width: AppDimensions.sm),
              _metaChip(
                icon: Icons.menu_book_rounded,
                label: item.bibleChapter != null
                    ? '${item.bibleBook} ${item.bibleChapter}'
                    : item.bibleBook!,
              ),
            ],
            if (item.tags.isNotEmpty) ...[
              const SizedBox(width: AppDimensions.sm),
              _metaChip(
                icon: Icons.sell_rounded,
                label: item.tags.first,
              ),
            ],
          ],
        ),
        if (item.tags.isNotEmpty && item.tags.length > 1) ...[
          const SizedBox(height: AppDimensions.sm),
          Wrap(
            spacing: AppDimensions.sm,
            runSpacing: AppDimensions.sm,
            children: item.tags.skip(1).map((tag) {
              return _metaChip(
                icon: Icons.sell_rounded,
                label: tag,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _metaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer(BuildContext context, String type) {
    return LibraryContentPlayer(
      key: ValueKey(item.id),
      type: type,
      videoUrl: item.videoUrl ?? item.fileUrl,
      audioUrl: item.fileUrl ?? item.videoUrl,
      pdfUrl: item.fileUrl ?? item.videoUrl,
      thumbnailUrl: item.thumbnailUrl,
      body: item.body,
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (item.body.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingXl),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.article_outlined,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Text(
              'No content available for this article yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Text(
        item.body,
        style: TextStyle(
          fontSize: 15,
          height: 1.7,
          color: isDark ? Colors.grey[200] : AppColors.textSecondary,
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
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
}
