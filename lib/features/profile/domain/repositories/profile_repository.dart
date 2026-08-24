import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/profile_entities.dart';

abstract class ProfileRepository {
  TaskEither<Failure, UserProfile> getProfile();
  TaskEither<Failure, UserProfile> updateProfile({
    String? fullName,
    String? username,
    String? phoneNumber,
  });
  TaskEither<Failure, UserProfile> updateAvatar(String avatarUrl);
  TaskEither<Failure, Unit> deleteAvatar();
  TaskEither<Failure, AccountStats> getAccountStats();
}
