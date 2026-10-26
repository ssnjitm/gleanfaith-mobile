import 'package:flutter/material.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../common/widgets/content_language_toggle.dart';
import '../../../../common/widgets/shimmer_widget.dart';

class VerseOfTheDayCard extends StatelessWidget {
  final String text;
  final String reference;
  final VoidCallback? onTap;
  final bool isLoading;

  /// True when the text is Nepali. Drives text sizing only — Devanagari
  /// conjuncts and the `।` danda need a little more line height than Latin text
  /// to stay legible, and a Nepali verse is usually longer than its English
  /// counterpart.
  final bool isNepali;

  /// True when the body on screen is not in the selected language, because that
  /// translation could not be fetched. A one-line notice says so out loud
  /// instead of passing the other language off as a translation. The verse
  /// itself is unchanged either way — only the language is.
  final bool showTranslationNotice;

  /// Actions on the verse itself. Hidden while loading and when a callback is
  /// absent, so the card degrades to a plain verse rather than a dead button.
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;
  final bool isBookmarked;

  const VerseOfTheDayCard({
    super.key,
    required this.text,
    required this.reference,
    this.onTap,
    this.isLoading = false,
    this.isNepali = false,
    this.showTranslationNotice = false,
    this.onCopy,
    this.onShare,
    this.onBookmark,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.all(
                  Radius.circular(AppDimensions.radiusLg),
                ),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: AppDimensions.xs),
                  if (isLoading) ...[
                    const ShimmerWidget(
                      width: double.infinity,
                      height: 14,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    const ShimmerWidget(
                      width: 220,
                      height: 14,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    const ShimmerWidget(width: 90, height: 12, borderRadius: 4),
                  ] else ...[
                    Text(
                      '"$text"',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: isNepali ? 1.6 : 1.4,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      '— $reference',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : AppColors.textMuted,
                      ),
                    ),
                    if (showTranslationNotice) ...[
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        // Names the language actually being shown, which is the
                        // opposite of the selected one whenever this renders.
                        isNepali
                            ? 'Nepali translation unavailable. Showing English.'
                            : 'English translation unavailable. Showing Nepali.',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                    _actions(isDark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(bool isDark) {
    if (isLoading ||
        (onCopy == null && onShare == null && onBookmark == null)) {
      return const SizedBox.shrink();
    }

    final color = isDark ? Colors.grey[400] : AppColors.textMuted;
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onCopy != null)
            IconButton(
              tooltip: 'Copy verse',
              icon: Icon(Icons.copy_rounded, size: 18, color: color),
              onPressed: onCopy,
              visualDensity: VisualDensity.compact,
            ),
          if (onBookmark != null)
            IconButton(
              tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark verse',
              icon: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 18,
                color: isBookmarked ? AppColors.primaryAmber : color,
              ),
              onPressed: onBookmark,
              visualDensity: VisualDensity.compact,
            ),
          if (onShare != null)
            IconButton(
              tooltip: 'Share verse',
              icon: Icon(Icons.share_rounded, size: 18, color: color),
              onPressed: onShare,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  /// Title on the left, `EN | NP` on the right. The toggle is hidden while
  /// loading so the header does not jump when the card resolves.
  Widget _header() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Verse of the Day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryAmber,
            ),
          ),
        ),
        if (!isLoading)
          const Padding(
            padding: EdgeInsets.only(left: AppDimensions.xs),
            child: ContentLanguageToggle(),
          ),
      ],
    );
  }
}
