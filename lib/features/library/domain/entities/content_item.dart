class ContentItem {
  final String id;
  final String title;
  final String body;
  final String type; // written | pdf | audio | video
  final String? fileUrl;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? bibleBook;
  final int? bibleChapter;
  final List<String> tags;
  final int? readTimeMinutes;

  const ContentItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.fileUrl,
    this.thumbnailUrl,
    this.videoUrl,
    this.bibleBook,
    this.bibleChapter,
    this.tags = const [],
    this.readTimeMinutes,
  });
}