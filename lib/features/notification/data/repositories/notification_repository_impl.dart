import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_entities.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  final Future<String> Function() _currentUserId;

  NotificationRepositoryImpl(this._remoteDataSource, this._currentUserId);

  @override
  TaskEither<Failure, NotificationListData> getMyNotifications({
    int limit = 50,
    int skip = 0,
  }) {
    return TaskEither.tryCatch(
      () async => (await _remoteDataSource.getMyNotifications(
        limit: limit,
        skip: skip,
        currentUserId: await _currentUserId(),
      ))
          .toEntity(),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, Unit> markAsRead(String notificationId) {
    return TaskEither.tryCatch(
      () async {
        await _remoteDataSource.markAsRead(notificationId);
        return unit;
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, Unit> markAllAsRead() {
    return TaskEither.tryCatch(
      () async {
        await _remoteDataSource.markAllAsRead();
        return unit;
      },
      (error, stackTrace) => handleError(error),
    );
  }
}
