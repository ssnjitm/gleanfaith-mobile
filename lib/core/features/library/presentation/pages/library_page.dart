import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../router/route_names.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Bible Learning')),
      body: Column(
        children: [
          _buildTypeFilter(context, libraryState.activeType, isDark),
          const SizedBox(height: AppDimensions.sm),
          Expanded(child: _buildContentList(libraryState, isDark)),
        ],
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

    return ListView.separated(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingMd,
        right: AppDimensions.paddingMd,
        bottom: AppDimensions.paddingXl,
      ),
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.sm),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _ContentCard(item: item);
      },
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentItem item;

  const _ContentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          onTap: () => context.push(RouteNames.libraryDetail, extra: item),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingSm),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 24),
                ),
                const SizedBox(width: AppDimensions.paddingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _typeLabel(item.type),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryAmber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.readTimeMinutes != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${item.readTimeMinutes} min read',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : AppColors.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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