import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/verse.dart';

class VerseResultTile extends StatelessWidget {
  final Verse verse;
  final VoidCallback onTap;

  const VerseResultTile({
    super.key,
    required this.verse,
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
                    verse.formattedReference,
                    style: TextStyle(
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
                      color: AppColors.primaryBlue.withOpacity(0.1),
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
              Text(
                verse.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}