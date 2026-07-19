import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  AuthRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  TaskEither<Failure, User> login(String email, String password) {
    return TaskEither.tryCatch(
      () async {
        final response = await _remoteDataSource.login(email, password);
        final data = response['data'] as Map<String, dynamic>? ?? response;
        final userData = data['user'] as Map<String, dynamic>? ?? data;
        final accessToken = data['accessToken'] as String? ?? '';
        final refreshToken = data['refreshToken'] as String? ?? '';

        final userModel = UserModel.fromJson(userData);
        if (accessToken.isNotEmpty) {
          await _storageService.write(AppConstants.tokenKey, accessToken);
        }
        if (refreshToken.isNotEmpty) {
          await _storageService.write(AppConstants.refreshTokenKey, refreshToken);
        }
        if (userModel.id.isNotEmpty) {
          await _storageService.write(AppConstants.userIdKey, userModel.id);
        }
        return userModel.toEntity();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, void> registerRequest({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) {
    return TaskEither.tryCatch(
      () async {
        await _remoteDataSource.registerRequest(
          email: email,
          password: password,
          fullName: fullName,
          username: username,
        );
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, Map<String, dynamic>> verifyOtp(String email, String otp) {
    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.verifyOtp(email, otp);
        final data = result['data'] as Map<String, dynamic>? ?? result;
        final userId = data['userId'] as String? ?? '';
        if (userId.isNotEmpty) {
          await _storageService.write(AppConstants.userIdKey, userId);
        }
        return data;
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, void> resendOtp(String email) {
    return TaskEither.tryCatch(
      () async => await _remoteDataSource.resendOtp(email),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, void> forgotPassword(String email) {
    return TaskEither.tryCatch(
      () async => await _remoteDataSource.forgotPassword(email),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return TaskEither.tryCatch(
      () async => await _remoteDataSource.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      ),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, void> logout() {
    return TaskEither.tryCatch(
      () async {
        try {
          await _remoteDataSource.logout();
        } catch (_) {}
        await _storageService.delete(AppConstants.tokenKey);
        await _storageService.delete(AppConstants.refreshTokenKey);
        await _storageService.delete(AppConstants.userIdKey);
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, User> getCurrentUser() {
    return TaskEither.tryCatch(
      () async {
        final userModel = await _remoteDataSource.getCurrentUser();
        return userModel.toEntity();
      },
      (error, stackTrace) => handleError(error),
    );
  }
}
