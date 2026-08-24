import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entities.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/notification_usecases.dart';

enum NotificationStatus { initial, loading, success, error }

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return NotificationRepositoryImpl(
    NotificationRemoteDataSource(dio),
    () async => await storage.read(AppConstants.userIdKey) ?? '',
  );
});

final getMyNotificationsUseCaseProvider = Provider<GetMyNotificationsUseCase>((ref) {
  return GetMyNotificationsUseCase(ref.watch(notificationRepositoryProvider));
});

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>((ref) {
  return MarkNotificationReadUseCase(ref.watch(notificationRepositoryProvider));
});

final markAllNotificationsReadUseCaseProvider =
    Provider<MarkAllNotificationsReadUseCase>((ref) {
  return MarkAllNotificationsReadUseCase(
      ref.watch(notificationRepositoryProvider));
});

class NotificationsState {
  final NotificationStatus status;
  final List<AppNotification> notifications;
  final int unreadCount;
  final String? message;

  const NotificationsState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.message,
  });

  bool get isLoading => status == NotificationStatus.loading;

  NotificationsState copyWith({
    NotificationStatus? status,
    List<AppNotification>? notifications,
    int? unreadCount,
    String? message,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      message: message,
    );
  }
}

/// Global provider so the drawer/home badge can watch unread counts
/// without owning the page lifecycle.
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref _ref;

  NotificationsNotifier(this._ref) : super(const NotificationsState());

  Future<void> load() async {
    state = state.copyWith(status: NotificationStatus.loading, message: null);
    final result =
        await _ref.read(getMyNotificationsUseCaseProvider)().run();
    result.fold(
      (failure) => state = state.copyWith(
        status: NotificationStatus.error,
        message: failure.message,
      ),
      (data) => state = state.copyWith(
        status: NotificationStatus.success,
        notifications: data.notifications,
        unreadCount: data.unread,
      ),
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final target = state.notifications
        .where((n) => n.id == notificationId && !n.isRead)
        .toList();
    if (target.isEmpty) return;

    final result =
        await _ref.read(markNotificationReadUseCaseProvider)(notificationId).run();
    result.fold(
      (_) {},
      (_) {
        final updated = state.notifications
            .map((n) =>
                n.id == notificationId ? _withRead(n) : n)
            .toList();
        final newUnread = (state.unreadCount - 1).clamp(0, state.unreadCount);
        state = state.copyWith(
          notifications: updated,
          unreadCount: newUnread,
        );
      },
    );
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0 && state.notifications.every((n) => n.isRead)) {
      return;
    }
    final result =
        await _ref.read(markAllNotificationsReadUseCaseProvider)().run();
    result.fold(
      (_) {},
      (_) {
        state = state.copyWith(
          notifications:
              state.notifications.map(_withRead).toList(),
          unreadCount: 0,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(status: NotificationStatus.success, message: null);
  }
}

AppNotification _withRead(AppNotification n) {
  return AppNotification(
    id: n.id,
    title: n.title,
    body: n.body,
    priority: n.priority,
    isRead: true,
    createdAt: n.createdAt,
  );
}
