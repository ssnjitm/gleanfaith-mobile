import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_entities.dart';

abstract class NotificationRepository {
  TaskEither<Failure, NotificationListData> getMyNotifications({
    int limit,
    int skip,
  });
  TaskEither<Failure, Unit> markAsRead(String notificationId);
  TaskEither<Failure, Unit> markAllAsRead();
}
