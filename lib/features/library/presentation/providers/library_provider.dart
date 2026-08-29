import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../../course/domain/entities/course_entities.dart' show Course;
import '../../../course/presentation/providers/course_providers.dart'
    show getCourseDetailUseCaseProvider, getCoursesUseCaseProvider;
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
  static const _cacheTtl = Duration(minutes: 5);
  static Set<String>? _cachedCourseContentIds;
  static DateTime? _cachedAt;

  LibraryNotifier(this._ref) : super(const LibraryState());

  Future<void> loadContents({String? type}) async {
    state = state.copyWith(status: LibraryStatus.loading, activeType: type, message: null);
    final excludedIds = await _courseContentIds();
    final result = await _ref.read(getContentsUseCaseProvider).call(type: type).run();
    result.fold(
      (failure) => state = state.copyWith(
        status: LibraryStatus.success,
        message: failure.message,
      ),
      (items) {
        final visible = items
            .where((e) => !e.isCourseMaterial && !excludedIds.contains(e.id))
            .toList();
        state = state.copyWith(
          status: LibraryStatus.success,
          items: visible,
          message: visible.isEmpty && items.isNotEmpty
              ? 'Only course materials available'
              : null,
        );
      },
    );
  }

  Future<Set<String>> _courseContentIds() async {
    final now = DateTime.now();
    final cached = _cachedCourseContentIds;
    if (cached != null && _cachedAt != null && now.difference(_cachedAt!) < _cacheTtl) {
      return cached;
    }
    final ids = <String>{};
    try {
      final coursesResult =
          await _ref.read(getCoursesUseCaseProvider).call(limit: 50).run();
      final courses = coursesResult.getOrElse((_) => const <Course>[]);
      if (courses.isEmpty) {
        _cachedCourseContentIds = ids;
        _cachedAt = now;
        return ids;
      }
      final details = await Future.wait(
        courses.map((c) => _ref.read(getCourseDetailUseCaseProvider).call(c.id).run()),
        eagerError: false,
      );
      for (final result in details) {
        result.fold((_) {}, (detail) {
          for (final lesson in detail.lessons) {
            for (final item in lesson.items) {
              if (!item.isQuiz && item.refId.isNotEmpty) {
                ids.add(item.refId);
              }
            }
          }
        });
      }
    } catch (_) {
      // Network hiccup — fall back to category-based filtering only.
    }
    _cachedCourseContentIds = ids;
    _cachedAt = now;
    return ids;
  }

  void setType(String? type) {
    state = state.copyWith(activeType: type);
    loadContents(type: type);
  }
}