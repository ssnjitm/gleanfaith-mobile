class AppNotification {
  final String id;
  final String title;
  final String body;
  final String priority;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    required this.isRead,
    this.createdAt,
  });
}

class NotificationListData {
  final List<AppNotification> notifications;
  final int total;
  final int unread;

  const NotificationListData({
    required this.notifications,
    required this.total,
    required this.unread,
  });

  static const empty =
      NotificationListData(notifications: [], total: 0, unread: 0);
}
