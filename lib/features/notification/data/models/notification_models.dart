import '../../domain/entities/notification_entities.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String priority;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotificationModel.fromJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final readBy = json['readBy'];
    final readByIds = readBy is List ? readBy.map((e) => e.toString()).toSet() : <String>{};
    final hasUserId = currentUserId.isNotEmpty;
    return AppNotificationModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      isRead: hasUserId && readByIds.isNotEmpty
          ? readByIds.contains(currentUserId)
          : false,
      createdAt: _parseDate(json['createdAt'] ?? json['scheduledAt']),
    );
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      priority: priority,
      isRead: isRead,
      createdAt: createdAt,
    );
  }
}

class NotificationListModel {
  final List<AppNotification> notifications;
  final int total;
  final int unread;

  const NotificationListModel({
    required this.notifications,
    required this.total,
    required this.unread,
  });

  factory NotificationListModel.fromJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final raw = json['notifications'];
    final items = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map((e) => AppNotificationModel.fromJson(e, currentUserId).toEntity())
            .toList()
        : <AppNotification>[];
    return NotificationListModel(
      notifications: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      unread: (json['unread'] as num?)?.toInt() ?? 0,
    );
  }

  NotificationListData toEntity() {
    return NotificationListData(
      notifications: notifications,
      total: total,
      unread: unread,
    );
  }
}
