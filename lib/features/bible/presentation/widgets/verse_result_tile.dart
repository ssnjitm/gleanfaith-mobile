import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/verse.dart';

class VerseResultTile extends StatelessWidget {
  final Verse verse;
  final VoidCallback onTap;
  final String? query;

  const VerseResultTile({
    super.key,
    required this.verse,
    required this.onTap,
    this.query,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    verse.formattedReference,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.xs,
                      vertical: AppDimensions.xs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      '${verse.book} ${verse.chapter}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xs),
              Text.rich(
                TextSpan(
                  children: _highlightMatches(verse.text, query),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _highlightMatches(String text, String? query) {
    if (query == null || query.trim().isEmpty) {
      return [TextSpan(text: text)];
    }

    final words = query
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.length >= 2)
        .toList();
    if (words.isEmpty) return [TextSpan(text: text)];

    final lowerText = text.toLowerCase();
    final ranges = <({int start, int end})>[];

    for (final word in words) {
      final lowerWord = word.toLowerCase();
      var idx = 0;
      while (true) {
        final found = lowerText.indexOf(lowerWord, idx);
        if (found == -1) break;
        ranges.add((start: found, end: found + word.length));
        idx = found + word.length;
      }
    }

    ranges.sort((a, b) => a.start.compareTo(b.start));

    final merged = <({int start, int end})>[];
    for (final range in ranges) {
      if (merged.isNotEmpty && range.start <= merged.last.end) {
        if (range.end > merged.last.end) {
          final last = merged.removeLast();
          merged.add((start: last.start, end: range.end));
        }
      } else {
        merged.add(range);
      }
    }

    if (merged.isEmpty) return [TextSpan(text: text)];

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in merged) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, range.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
            backgroundColor: Color(0x2B2563EB),
          ),
        ),
      );
      cursor = range.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
  }
}
