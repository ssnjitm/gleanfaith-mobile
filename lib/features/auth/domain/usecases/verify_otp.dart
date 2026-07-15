import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository _repository;
  VerifyOtpUseCase(this._repository);

  TaskEither<Failure, Map<String, dynamic>> call(String email, String otp) {
    return _repository.verifyOtp(email, otp);
  }
}
