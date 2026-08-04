import 'package:flutter/material.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/topic.dart';

class PopularTopicsGrid extends StatelessWidget {
  final List<Topic> topics;
  final Function(String topicName) onTopicTap;

  const PopularTopicsGrid({
    super.key,
    required this.topics,
    required this.onTopicTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemCount: topics.length > 20 ? 20 : topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return _TopicChip(
          topic: topic,
          onTap: () => onTopicTap(topic.name),
        );
      },
    );
  }
}

class _TopicChip extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;

  const _TopicChip({
    required this.topic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            topic.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}