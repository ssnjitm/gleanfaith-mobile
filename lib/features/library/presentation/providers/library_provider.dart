import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../data/datasources/content_remote_datasource.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../domain/entities/content_item.dart';
import '../../domain/repositories/library_repository.dart';
import '../../domain/usecases/get_contents.dart';

enum LibraryStatus { initial, loading, success, error }

class LibraryState {
  final LibraryStatus status;
  final List<ContentItem> items;
  final String? activeType;
  final String? message;

  const LibraryState({
    this.status = LibraryStatus.initial,
    this.items = const [],
    this.activeType,
    this.message,
  });

  LibraryState copyWith({
    LibraryStatus? status,
    List<ContentItem>? items,
    String? activeType,
    String? message,
  }) {
    return LibraryState(
      status: status ?? this.status,
      items: items ?? this.items,
      activeType: activeType ?? this.activeType,
      message: message,
    );
  }
}

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LibraryRepositoryImpl(ContentRemoteDataSource(dio));
});

final getContentsUseCaseProvider = Provider<GetContentsUseCase>((ref) {
  return GetContentsUseCase(ref.watch(libraryRepositoryProvider));
});

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier(ref);
});

class LibraryNotifier extends StateNotifier<LibraryState> {
  final Ref _ref;

  LibraryNotifier(this._ref) : super(const LibraryState());

  Future<void> loadContents({String? type}) async {
    state = state.copyWith(status: LibraryStatus.loading, activeType: type, message: null);
    final result = await _ref.read(getContentsUseCaseProvider).call(type: type).run();
    result.fold(
      (failure) => state = state.copyWith(
        status: LibraryStatus.success,
        message: failure.message,
      ),
      (items) => state = state.copyWith(
        status: LibraryStatus.success,
        items: items,
      ),
    );
  }

  void setType(String? type) {
    state = state.copyWith(activeType: type);
    loadContents(type: type);
  }
}