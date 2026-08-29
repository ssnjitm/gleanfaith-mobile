import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../router/route_names.dart';
import '../../../../../features/course/presentation/pages/courses_page.dart';
import '../../../../../features/library/presentation/providers/library_provider.dart';
import '../../../../../features/library/domain/entities/content_item.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  static const _types = [
    (label: 'All', value: null),
    (label: 'Articles', value: 'written'),
    (label: 'Videos', value: 'video'),
    (label: 'Audio', value: 'audio'),
    (label: 'PDF', value: 'pdf'),
  ];

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(libraryProvider.notifier).loadContents());
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      initialIndex: 1,
      child: Scaffold(
        backgroundColor: AppColors.bgGray,
        appBar: AppBar(
          title: const Text('Bible Learning'),
          bottom: TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor:
                isDark ? Colors.grey[400] : AppColors.textMuted,
            indicatorColor: AppColors.primaryBlue,
            dividerColor:
                isDark ? const Color(0xFF334155) : AppColors.borderLight,
            tabs: const [
              Tab(text: 'Contents'),
              Tab(text: 'Courses'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                _buildTypeFilter(context, libraryState.activeType, isDark),
                const SizedBox(height: AppDimensions.sm),
                Expanded(child: _buildContentList(libraryState, isDark)),
              ],
            ),
            const CoursesGridBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilter(BuildContext context, String? activeType, bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        children: LibraryPage._types.map((type) {
          final selected = type.value == activeType;
          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.sm),
            child: ChoiceChip(
              label: Text(type.label),
              selected: selected,
              onSelected: (_) {
                ref.read(libraryProvider.notifier).setType(type.value);
              },
              selectedColor: AppColors.primaryBlue,
              backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : AppColors.textSecondary),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentList(LibraryState state, bool isDark) {
    if (state.status == LibraryStatus.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 64,
              color: isDark ? Colors.grey[600] : AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Text(
              state.message ?? 'No learning content yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMd,
        AppDimensions.paddingSm,
        AppDimensions.paddingMd,
        AppDimensions.paddingXl,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimensions.paddingMd,
        crossAxisSpacing: AppDimensions.paddingMd,
        childAspectRatio: 0.78,
      ),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _ContentGridCard(item: item, isDark: isDark);
      },
    );
  }
}

class _ContentGridCard extends StatelessWidget {
  final ContentItem item;
  final bool isDark;

  const _ContentGridCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RouteNames.libraryDetail, extra: item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: _thumbnail(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingSm + 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _typeLabel(item.type),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (item.readTimeMinutes != null)
                          Text(
                            '${item.readTimeMinutes} min',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark
                                  ? Colors.grey[500]
                                  : AppColors.textLight,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get accent {
    switch (item.type) {
      case 'video':
        return AppColors.errorLight;
      case 'audio':
        return AppColors.primaryAmber;
      case 'pdf':
        return AppColors.error;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData get icon {
    switch (item.type) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'audio':
        return Icons.headphones_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  Widget _thumbnail() {
    final url = item.thumbnailUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _defaultThumb();
        },
        errorBuilder: (_, _, _) => _defaultThumb(),
      );
    }
    return _defaultThumb();
  }

  Widget _defaultThumb() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.35),
            accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 40, color: accent),
      ),
    );
  }

  String _typeLabel(String type) {
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
}