import 'package:equatable/equatable.dart';
import '../../domain/entities/topic.dart';

class TopicModel extends Equatable {
  final int id;
  final String topicName;
  final int verseCount;

  const TopicModel({
    required this.id,
    required this.topicName,
    this.verseCount = 0,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as int,
      topicName: json['topic_name'] as String,
      verseCount: json['verse_count'] as int? ?? 0,
    );
  }

  Topic toEntity() => Topic(
        id: id,
        name: topicName,
        verseCount: verseCount,
      );

  @override
  List<Object?> get props => [id, topicName, verseCount];
}