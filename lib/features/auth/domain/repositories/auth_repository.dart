import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  TaskEither<Failure, User> login(String email, String password);
  TaskEither<Failure, void> registerRequest({
    required String email,
    required String password,
    required String fullName,
    required String username,
  });
  TaskEither<Failure, Map<String, dynamic>> verifyOtp(String email, String otp);
  TaskEither<Failure, void> resendOtp(String email);
  TaskEither<Failure, void> forgotPassword(String email);
  TaskEither<Failure, void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
  TaskEither<Failure, void> logout();
  TaskEither<Failure, User> getCurrentUser();
}
