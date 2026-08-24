import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/profile_entities.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository _repository;
  GetProfileUseCase(this._repository);

  TaskEither<Failure, UserProfile> call() {
    return _repository.getProfile();
  }
}

class UpdateProfileUseCase {
  final ProfileRepository _repository;
  UpdateProfileUseCase(this._repository);

  TaskEither<Failure, UserProfile> call({
    String? fullName,
    String? username,
    String? phoneNumber,
  }) {
    return _repository.updateProfile(
      fullName: fullName,
      username: username,
      phoneNumber: phoneNumber,
    );
  }
}
