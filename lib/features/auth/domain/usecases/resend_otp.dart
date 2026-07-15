import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ResendOtpUseCase {
  final AuthRepository _repository;
  ResendOtpUseCase(this._repository);

  TaskEither<Failure, void> call(String email) {
    return _repository.resendOtp(email);
  }
}
