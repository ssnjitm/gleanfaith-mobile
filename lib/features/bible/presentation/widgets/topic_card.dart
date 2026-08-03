import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/topic.dart';

class TopicCard extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;

  const TopicCard({
    super.key,
    required this.topic,
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
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: const Icon(
                  Icons.topic,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (topic.verseCount > 0)
                      Text(
                        '${topic.verseCount} verses',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}