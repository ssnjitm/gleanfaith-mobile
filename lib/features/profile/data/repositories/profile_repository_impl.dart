import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/profile_entities.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  TaskEither<Failure, UserProfile> getProfile() {
    return TaskEither.tryCatch(
      () async => (await _remoteDataSource.getProfile()).toEntity(),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, UserProfile> updateProfile({
    String? fullName,
    String? username,
    String? phoneNumber,
  }) {
    return TaskEither.tryCatch(
      () async => (await _remoteDataSource.updateProfile(
        fullName: fullName,
        username: username,
        phoneNumber: phoneNumber,
      ))
          .toEntity(),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, UserProfile> updateAvatar(String avatarUrl) {
    return TaskEither.tryCatch(
      () async => (await _remoteDataSource.updateAvatar(avatarUrl)).toEntity(),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, Unit> deleteAvatar() {
    return TaskEither.tryCatch(
      () async {
        await _remoteDataSource.deleteAvatar();
        return unit;
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, AccountStats> getAccountStats() {
    return TaskEither.tryCatch(
      () async => (await _remoteDataSource.getAccountStats()).toEntity(),
      (error, stackTrace) => handleError(error),
    );
  }
}
