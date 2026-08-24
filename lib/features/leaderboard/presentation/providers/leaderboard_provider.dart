import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../data/datasources/leaderboard_remote_datasource.dart';
import '../../data/repositories/leaderboard_repository_impl.dart';
import '../../domain/entities/leaderboard_entities.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../domain/usecases/get_leaderboard.dart';
import '../../domain/usecases/get_my_ranking.dart';

enum LeaderboardStatus { initial, loading, success, error }

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LeaderboardRepositoryImpl(LeaderboardRemoteDataSource(dio));
});

final getLeaderboardUseCaseProvider = Provider<GetLeaderboardUseCase>((ref) {
  return GetLeaderboardUseCase(ref.watch(leaderboardRepositoryProvider));
});

final getMyRankingUseCaseProvider = Provider<GetMyRankingUseCase>((ref) {
  return GetMyRankingUseCase(ref.watch(leaderboardRepositoryProvider));
});

class LeaderboardState {
  final LeaderboardStatus status;
  final LeaderboardPeriod selectedPeriod;
  final LeaderboardData? data;
  final MyRanking myRanking;
  final String? message;

  const LeaderboardState({
    this.status = LeaderboardStatus.initial,
    this.selectedPeriod = LeaderboardPeriod.weekly,
    this.data,
    this.myRanking = MyRanking.empty,
    this.message,
  });

  bool get isLoading => status == LeaderboardStatus.loading;

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    LeaderboardPeriod? selectedPeriod,
    LeaderboardData? data,
    MyRanking? myRanking,
    String? message,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      data: data ?? this.data,
      myRanking: myRanking ?? this.myRanking,
      message: message,
    );
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref);
});

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref _ref;

  LeaderboardNotifier(this._ref) : super(const LeaderboardState());

  Future<void> load() async {
    state = state.copyWith(status: LeaderboardStatus.loading, message: null);
    await Future.wait([_loadEntries(), _loadMyRanking()]);
    if (state.data != null) {
      state = state.copyWith(status: LeaderboardStatus.success);
    }
  }

  Future<void> changePeriod(LeaderboardPeriod period) async {
    if (period == state.selectedPeriod) return;
    state = state.copyWith(selectedPeriod: period, status: LeaderboardStatus.loading);
    await _loadEntries();
    if (state.data != null) {
      state = state.copyWith(status: LeaderboardStatus.success);
    }
  }

  Future<void> _loadEntries() async {
    final result = await _ref.read(getLeaderboardUseCaseProvider)(
      period: state.selectedPeriod,
      limit: 100,
    ).run();
    result.fold(
      (failure) => state = state.copyWith(
        status: LeaderboardStatus.error,
        message: failure.message,
      ),
      (data) => state = state.copyWith(data: data),
    );
  }

  Future<void> _loadMyRanking() async {
    final result = await _ref.read(getMyRankingUseCaseProvider)().run();
    result.fold(
      (_) {},
      (ranking) => state = state.copyWith(myRanking: ranking),
    );
  }

  void clearError() {
    state = state.copyWith(status: LeaderboardStatus.initial, message: null);
  }
}
