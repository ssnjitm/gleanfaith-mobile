import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/topic_verse.dart';

class VerseCard extends StatelessWidget {
  final TopicVerse topicVerse;
  final VoidCallback onTap;

  const VerseCard({
    super.key,
    required this.topicVerse,
    required this.onTap,
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
                    topicVerse.verseReference,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  if (topicVerse.votes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.xs,
                        vertical: AppDimensions.xs / 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAmber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 12,
                            color: AppColors.primaryAmber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${topicVerse.votes}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primaryAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                topicVerse.verseText,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Row(
                children: [
                  const Icon(
                    Icons.book_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${topicVerse.book} ${topicVerse.chapter}:${topicVerse.verse}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}