import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_entities.dart';
import '../repositories/notification_repository.dart';

class GetMyNotificationsUseCase {
  final NotificationRepository _repository;
  GetMyNotificationsUseCase(this._repository);

  TaskEither<Failure, NotificationListData> call({int limit = 50, int skip = 0}) {
    return _repository.getMyNotifications(limit: limit, skip: skip);
  }
}

class MarkNotificationReadUseCase {
  final NotificationRepository _repository;
  MarkNotificationReadUseCase(this._repository);

  TaskEither<Failure, Unit> call(String notificationId) {
    return _repository.markAsRead(notificationId);
  }
}

class MarkAllNotificationsReadUseCase {
  final NotificationRepository _repository;
  MarkAllNotificationsReadUseCase(this._repository);

  TaskEither<Failure, Unit> call() {
    return _repository.markAllAsRead();
  }
}
