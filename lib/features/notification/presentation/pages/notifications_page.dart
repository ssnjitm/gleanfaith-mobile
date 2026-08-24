import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/extensions/datetime_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/common/widgets/app_empty_state.dart';
import '../../../../core/common/widgets/app_error_widget.dart';
import '../../../../core/common/widgets/app_loading.dart';
import '../../../../../features/notification/domain/entities/notification_entities.dart';
import '../../../../../features/notification/presentation/providers/notification_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final state = ref.read(notificationsProvider);
      if (state.status == NotificationStatus.initial) {
        ref.read(notificationsProvider.notifier).load();
      }
    });
  }

  Future<void> _refresh() => ref.read(notificationsProvider.notifier).load();

  void _markAllRead() =>
      ref.read(notificationsProvider.notifier).markAllAsRead();

  void _onTapNotification(AppNotification notification) {
    if (!notification.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, NotificationsState state) {
    if (state.status == NotificationStatus.loading &&
        state.notifications.isEmpty) {
      return const AppLoading(message: 'Loading notifications...');
    }

    if (state.status == NotificationStatus.error &&
        state.notifications.isEmpty) {
      return AppErrorWidget(
        message: state.message ?? 'Could not load notifications.',
        onRetry: () => ref.read(notificationsProvider.notifier).load(),
      );
    }

    if (state.notifications.isEmpty) {
      return AppEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications',
        subtitle: 'You are all caught up. New updates will appear here.',
        actionLabel: 'Refresh',
        onAction: _refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        itemCount: state.notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.sm),
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => _onTapNotification(notification),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  Color get _priorityColor {
    switch (notification.priority.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'low':
        return AppColors.textMuted;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData get _priorityIcon {
    switch (notification.priority.toLowerCase()) {
      case 'urgent':
        return Icons.priority_high_rounded;
      case 'high':
        return Icons.notifications_active_outlined;
      case 'low':
        return Icons.notifications_none_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread
          ? AppColors.primaryBlue.withValues(alpha: isDark ? 0.12 : 0.06)
          : (isDark ? const Color(0xFF1E293B) : AppColors.bgWhite),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isUnread
                  ? AppColors.primaryBlue.withValues(alpha: 0.4)
                  : (isDark ? const Color(0xFF334155) : AppColors.borderLight),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(_priorityIcon, size: 20, color: _priorityColor),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isDark
                                  ? Colors.grey[100]
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: isDark
                              ? Colors.grey[400]
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (notification.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        notification.createdAt!.timeAgo(),
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDark ? Colors.grey[500] : AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
