import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../data/bible_study_mapper.dart';
import '../../data/datasources/bible_study_remote_datasource.dart';
import '../../data/repositories/bible_study_repository_impl.dart';
import '../../domain/entities/bible_study_entities.dart';
import '../../domain/repositories/bible_study_repository.dart';
import '../../domain/usecases/bible_study_usecases.dart';

enum BibleStudyStatus { initial, loading, success, error }

// ── Repository + use cases ────────────────────────────────────────────────

final bibleStudyRepositoryProvider = Provider<BibleStudyRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BibleStudyRepositoryImpl(BibleStudyRemoteDataSource(dio));
});

final saveReadingPositionUseCaseProvider = Provider<SaveReadingPositionUseCase>((ref) {
  return SaveReadingPositionUseCase(ref.watch(bibleStudyRepositoryProvider));
});

final getRecentReadingUseCaseProvider = Provider<GetRecentReadingUseCase>((ref) {
  return GetRecentReadingUseCase(ref.watch(bibleStudyRepositoryProvider));
});

final getNotesUseCaseProvider = Provider<GetNotesUseCase>((ref) {
  return GetNotesUseCase(ref.watch(bibleStudyRepositoryProvider));
});

final createNoteUseCaseProvider = Provider<CreateNoteUseCase>((ref) {
  return CreateNoteUseCase(ref.watch(bibleStudyRepositoryProvider));
});

final updateNoteUseCaseProvider = Provider<UpdateNoteUseCase>((ref) {
  return UpdateNoteUseCase(ref.watch(bibleStudyRepositoryProvider));
});

final deleteNoteUseCaseProvider = Provider<DeleteNoteUseCase>((ref) {
  return DeleteNoteUseCase(ref.watch(bibleStudyRepositoryProvider));
});

// ── Continue reading (recent positions) ───────────────────────────────────

class RecentReadingState {
  final BibleStudyStatus status;
  final List<ReadingPosition> positions;
  final String? message;

  const RecentReadingState({
    this.status = BibleStudyStatus.initial,
    this.positions = const [],
    this.message,
  });

  RecentReadingState copyWith({
    BibleStudyStatus? status,
    List<ReadingPosition>? positions,
    String? message,
  }) {
    return RecentReadingState(
      status: status ?? this.status,
      positions: positions ?? this.positions,
      message: message,
    );
  }
}

/// Global recent reading history — powers the Home "Continue Reading" card.
final recentReadingProvider =
    StateNotifierProvider<RecentReadingNotifier, RecentReadingState>((ref) {
  return RecentReadingNotifier(ref);
});

class RecentReadingNotifier extends StateNotifier<RecentReadingState> {
  final Ref _ref;

  RecentReadingNotifier(this._ref) : super(const RecentReadingState());

  Future<void> load({int limit = 5}) async {
    state = state.copyWith(status: BibleStudyStatus.loading, message: null);
    final result = await _ref.read(getRecentReadingUseCaseProvider)(limit: limit).run();
    result.fold(
      (failure) => state = state.copyWith(
        status: BibleStudyStatus.error,
        message: failure.message,
      ),
      (positions) => state = state.copyWith(
        status: BibleStudyStatus.success,
        positions: positions,
      ),
    );
  }

  /// Fire-and-forget upsert of the current reading position.
  Future<void> savePosition({
    required String bookName,
    required int chapter,
    required int verse,
  }) async {
    final result = await _ref.read(saveReadingPositionUseCaseProvider)(
      bookName: bookName,
      chapter: chapter,
      verse: verse,
    ).run();
    result.fold(
      (_) {}, // Upserts are best-effort; errors surface on the next load.
      (_) {
        if (state.status == BibleStudyStatus.success) {
          load();
        }
      },
    );
  }
}

// ── Chapter notes (per chapter) ────────────────────────────────────────────

typedef ChapterArg = ({String book, int chapter});

class ChapterNotesState {
  final BibleStudyStatus status;
  final List<ChapterNote> notes;
  final bool isMutating;
  final String? message;

  const ChapterNotesState({
    this.status = BibleStudyStatus.initial,
    this.notes = const [],
    this.isMutating = false,
    this.message,
  });

  ChapterNotesState copyWith({
    BibleStudyStatus? status,
    List<ChapterNote>? notes,
    bool? isMutating,
    String? message,
  }) {
    return ChapterNotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isMutating: isMutating ?? this.isMutating,
      message: message,
    );
  }
}

final chapterNotesProvider =
    StateNotifierProvider.family<ChapterNotesNotifier, ChapterNotesState, ChapterArg>(
  (ref, arg) => ChapterNotesNotifier(ref, arg),
);

class ChapterNotesNotifier extends StateNotifier<ChapterNotesState> {
  final Ref _ref;
  final ChapterArg _arg;

  ChapterNotesNotifier(this._ref, this._arg) : super(const ChapterNotesState());

  int get _chapter => _arg.chapter;

  Future<void> load() async {
    state = state.copyWith(status: BibleStudyStatus.loading, message: null);
    final result = await _ref
        .read(getNotesUseCaseProvider)(
          bookId: bookCodeForName(_arg.book),
          chapter: _chapter,
        )
        .run();
    result.fold(
      (failure) => state = state.copyWith(
        status: BibleStudyStatus.error,
        message: failure.message,
      ),
      (notes) => state = state.copyWith(
        status: BibleStudyStatus.success,
        notes: notes,
      ),
    );
  }

  Future<void> add(String content) async {
    if (state.isMutating || content.trim().isEmpty) return;
    state = state.copyWith(isMutating: true, message: null);

    final result = await _ref.read(createNoteUseCaseProvider)(
      bookName: _arg.book,
      chapter: _chapter,
      content: content.trim(),
    ).run();

    result.fold(
      (failure) => state = state.copyWith(isMutating: false, message: failure.message),
      (note) => state = state.copyWith(
        isMutating: false,
        notes: [...state.notes, note],
      ),
    );
  }

  Future<void> update(String noteId, String content) async {
    if (state.isMutating) return;
    state = state.copyWith(isMutating: true, message: null);

    final trimmed = content.trim();
    final result = trimmed.isEmpty
        ? await _ref.read(deleteNoteUseCaseProvider)(noteId).run()
        : await _ref
            .read(updateNoteUseCaseProvider)(
              noteId: noteId,
              content: trimmed,
              chapter: _chapter,
            )
            .run();

    result.fold(
      (failure) => state = state.copyWith(isMutating: false, message: failure.message),
      (_) => state = state.copyWith(
        isMutating: false,
        notes: trimmed.isEmpty
            ? state.notes.where((n) => n.id != noteId).toList()
            : state.notes
                .map((n) => n.id == noteId
                    ? ChapterNote(
                        id: n.id,
                        bookId: n.bookId,
                        bookName: n.bookName,
                        chapter: _chapter,
                        content: trimmed,
                        updatedAt: DateTime.now(),
                      )
                    : n)
                .toList(),
      ),
    );
  }

  Future<void> remove(String noteId) async {
    if (state.isMutating) return;
    state = state.copyWith(isMutating: true, message: null);

    final result = await _ref.read(deleteNoteUseCaseProvider)(noteId).run();

    result.fold(
      (failure) => state = state.copyWith(isMutating: false, message: failure.message),
      (_) => state = state.copyWith(
        isMutating: false,
        notes: state.notes.where((n) => n.id != noteId).toList(),
      ),
    );
  }
}

// ── Notes (global list) ────────────────────────────────────────────────────

class NotesState {
  final BibleStudyStatus status;
  final List<ChapterNote> notes;
  final String? message;

  const NotesState({
    this.status = BibleStudyStatus.initial,
    this.notes = const [],
    this.message,
  });

  NotesState copyWith({
    BibleStudyStatus? status,
    List<ChapterNote>? notes,
    String? message,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      message: message,
    );
  }
}

/// All notes across every book — used by the Notes page.
final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier(ref);
});

class NotesNotifier extends StateNotifier<NotesState> {
  final Ref _ref;

  NotesNotifier(this._ref) : super(const NotesState());

  Future<void> load() async {
    state = state.copyWith(status: BibleStudyStatus.loading, message: null);
    final result = await _ref.read(getNotesUseCaseProvider)().run();
    result.fold(
      (failure) => state = state.copyWith(
        status: BibleStudyStatus.error,
        message: failure.message,
      ),
      (notes) => state = state.copyWith(
        status: BibleStudyStatus.success,
        notes: notes,
      ),
    );
  }

  Future<void> remove(String noteId) async {
    final result = await _ref.read(deleteNoteUseCaseProvider)(noteId).run();
    result.fold(
      (failure) => state = state.copyWith(message: failure.message),
      (_) => state = state.copyWith(
        notes: state.notes.where((n) => n.id != noteId).toList(),
        message: null,
      ),
    );
  }
}