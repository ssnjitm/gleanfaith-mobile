import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class RegisterRequestUseCase {
  final AuthRepository _repository;
  RegisterRequestUseCase(this._repository);

  TaskEither<Failure, void> call({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) {
    return _repository.registerRequest(
      email: email,
      password: password,
      fullName: fullName,
      username: username,
    );
  }
}
