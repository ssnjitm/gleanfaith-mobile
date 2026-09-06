import 'package:flutter/material.dart';

class ContentThumbnail extends StatelessWidget {
  final String type; // written | pdf | audio | video
  final String? thumbnailUrl;
  final double iconSize;
  final BorderRadius? borderRadius;

  const ContentThumbnail({
    super.key,
    required this.type,
    this.thumbnailUrl,
    this.iconSize = 40,
    this.borderRadius,
  });

  List<Color> get _gradient {
    switch (type) {
      case 'video':
        return const [Color(0xFF0EA5E9), Color(0xFF6366F1)];
      case 'audio':
        return const [Color(0xFF8B5CF6), Color(0xFFC084FC)];
      case 'pdf':
        return const [Color(0xFFF43F5E), Color(0xFFFB923C)];
      default:
        return const [Color(0xFF10B981), Color(0xFF34D399)];
    }
  }

  IconData get _icon {
    switch (type) {
      case 'video':
        return Icons.play_circle_fill_rounded;
      case 'audio':
        return Icons.headphones_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  String get _label {
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

  @override
  Widget build(BuildContext context) {
    final url = thumbnailUrl;
    if (url != null && url.isNotEmpty) {
      Widget image = Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder();
        },
        errorBuilder: (_, _, _) => _placeholder(),
      );
      final radius = borderRadius;
      if (radius != null) {
        image = ClipRRect(borderRadius: radius, child: image);
      }
      return image;
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -16,
            top: -16,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, color: Colors.white, size: iconSize),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}