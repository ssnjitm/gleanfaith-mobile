import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entities.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_account_stats.dart';
import '../../domain/usecases/profile_usecases.dart';

enum ProfileStatus { initial, loading, success, error }

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepositoryImpl(ProfileRemoteDataSource(dio));
});

final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.watch(profileRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(profileRepositoryProvider));
});

final getAccountStatsUseCaseProvider = Provider<GetAccountStatsUseCase>((ref) {
  return GetAccountStatsUseCase(ref.watch(profileRepositoryProvider));
});

class ProfileState {
  final ProfileStatus status;
  final UserProfile? profile;
  final AccountStats? stats;
  final String? message;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.stats,
    this.message,
  });

  bool get isSaving => status == ProfileStatus.loading;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    AccountStats? stats,
    String? message,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      stats: stats ?? this.stats,
      message: message,
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileNotifier(this._ref) : super(const ProfileState());

  Future<void> load() async {
    state = state.copyWith(status: ProfileStatus.loading, message: null);
    await Future.wait([_loadProfile(), _loadStats()]);
    if (state.profile != null || state.stats != null) {
      state = state.copyWith(status: ProfileStatus.success);
    } else if (state.status != ProfileStatus.error) {
      state = state.copyWith(
        status: ProfileStatus.success,
      );
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String username,
    required String phoneNumber,
  }) async {
    state = state.copyWith(status: ProfileStatus.loading, message: null);
    final result = await _ref.read(updateProfileUseCaseProvider)(
      fullName: fullName.trim(),
      username: username.trim(),
      phoneNumber: phoneNumber.trim().isEmpty ? null : phoneNumber.trim(),
    ).run();
    return result.fold(
      (failure) {
        state = state.copyWith(status: ProfileStatus.error, message: failure.message);
        return false;
      },
      (profile) {
        state = state.copyWith(status: ProfileStatus.success, profile: profile);
        _syncToAuth(profile);
        return true;
      },
    );
  }

  void clearMessage() {
    state = state.copyWith(message: null);
  }

  Future<void> _loadProfile() async {
    final result = await _ref.read(getProfileUseCaseProvider)().run();
    result.fold(
      (failure) => state =
          state.copyWith(status: ProfileStatus.error, message: failure.message),
      (profile) {
        state = state.copyWith(profile: profile);
        _syncToAuth(profile);
      },
    );
  }

  Future<void> _loadStats() async {
    final result = await _ref.read(getAccountStatsUseCaseProvider)().run();
    result.fold((_) {}, (stats) => state = state.copyWith(stats: stats));
  }

  void _syncToAuth(UserProfile profile) {
    final authUser = _ref.read(authProvider).user;
    if (authUser == null) return;
    final updated = authUser.copyWithProfile(
      fullName: profile.fullName,
      username: profile.username,
      phoneNumber: profile.phoneNumber,
      avatar: profile.avatar,
    );
    _ref.read(authProvider.notifier).updateUser(updated);
  }
}
