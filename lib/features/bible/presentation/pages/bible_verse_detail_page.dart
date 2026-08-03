import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glean_faith_app/core/common/extensions/context_extensions.dart';
import 'package:glean_faith_app/core/router/route_names.dart';
import 'package:glean_faith_app/core/services/database_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/common/widgets/app_scaffold.dart';

class BibleVerseDetailPage extends ConsumerStatefulWidget {
  final String book;
  final int chapter;
  final int verse;

  const BibleVerseDetailPage({
    super.key,
    required this.book,
    required this.chapter,
    required this.verse,
  });

  @override
  ConsumerState<BibleVerseDetailPage> createState() => _BibleVerseDetailPageState();
}

class _BibleVerseDetailPageState extends ConsumerState<BibleVerseDetailPage> {
  Map<String, dynamic>? _verseData;
  List<Map<String, dynamic>> _contextVerses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVerseData();
  }

  Future<void> _loadVerseData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = await DatabaseService.instance.bibleDatabase;
      
      // Get the specific verse
      final verseResults = await db.rawQuery('''
        SELECT 
          book,
          chapter,
          verse,
          text
        FROM bible_verses
        WHERE book = ? AND chapter = ? AND verse = ?
        LIMIT 1
      ''', [widget.book, widget.chapter, widget.verse]);
      
      if (verseResults.isNotEmpty) {
        _verseData = verseResults.first;
      } else {
        _errorMessage = 'Verse not found';
      }

      // Get context verses (2 before and 2 after)
      final contextResults = await db.rawQuery('''
        SELECT 
          book,
          chapter,
          verse,
          text
        FROM bible_verses
        WHERE book = ? 
          AND chapter = ? 
          AND verse BETWEEN ? AND ?
        ORDER BY verse
      ''', [widget.book, widget.chapter, widget.verse - 2, widget.verse + 2]);
      
      _contextVerses = contextResults;
    } catch (e) {
      _errorMessage = 'Failed to load verse: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: AppBar(
        title: Text('${widget.book} ${widget.chapter}:${widget.verse}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _verseData != null
                ? () {
                    // TODO: Implement copy
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _verseData != null
                ? () {
                    // TODO: Implement bookmark
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bookmarked!')),
                    );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _verseData != null
                ? () {
                    // TODO: Implement share
                  }
                : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadVerseData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _verseData == null
                  ? const Center(
                      child: Text('Verse not found'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Context label
                          Text(
                            'Context (${widget.book} ${widget.chapter})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Context verses
                          ..._contextVerses.map((verse) {
                            final isTargetVerse = verse['verse'] == widget.verse;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isTargetVerse
                                    ? AppColors.primaryBlue.withOpacity(0.1)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: isTargetVerse
                                    ? Border.all(
                                        color: AppColors.primaryBlue.withOpacity(0.3),
                                      )
                                    : null,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '${verse['verse']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isTargetVerse
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isTargetVerse
                                            ? AppColors.primaryBlue
                                            : isDark
                                                ? Colors.grey[500]
                                                : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      verse['text'] as String,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        fontWeight: isTargetVerse
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isTargetVerse
                                            ? AppColors.primaryBlue
                                            : isDark
                                                ? Colors.grey[300]
                                                : Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 24),

                          // Full verse text (highlighted)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlue.withOpacity(0.15),
                                  AppColors.primaryAmber.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryBlue.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_verseData?['book']} ${_verseData?['chapter']}:${_verseData?['verse']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _verseData?['text'] as String? ?? '',
                                  style: TextStyle(
                                    fontSize: 18,
                                    height: 1.8,
                                    color: isDark ? Colors.grey[200] : Colors.grey[900],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Related topics (if available)
                          _buildRelatedTopics(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildRelatedTopics() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService.instance.getTopicsByBook(widget.book),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final topics = snapshot.data!.take(5).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Related Topics in ${widget.book}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topics.map((topic) {
                return ActionChip(
                  label: Text(topic['topic_name'] as String),
                  onPressed: () {
                    // Navigate to topic detail
                    context.pushNamed(
                      RouteNames.bibleTopicDetail,
                      pathParameters: {
                        'topic': Uri.encodeComponent(topic['topic_name'] as String),
                      },
                    );
                  },
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}