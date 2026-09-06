import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/course_progress_entities.dart';

class CourseQuizAttemptsState {
  final Map<String, CourseQuizAttempt> attempts;
  final bool loaded;

  const CourseQuizAttemptsState({this.attempts = const {}, this.loaded = false});
}

class CourseQuizAttemptsNotifier extends StateNotifier<CourseQuizAttemptsState> {
  final Ref _ref;

  CourseQuizAttemptsNotifier(this._ref)
      : super(const CourseQuizAttemptsState());

  Future<void> _ensureLoaded() async {
    if (state.loaded) return;
    final raw = await _ref
        .read(storageProvider)
        .read(AppConstants.courseQuizAttemptsKey);
    final attempts = <String, CourseQuizAttempt>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              attempts[key] = CourseQuizAttempt.fromJson(value);
            }
          });
        }
      } catch (_) {
        // Corrupt local data — ignore.
      }
    }
    state = CourseQuizAttemptsState(attempts: attempts, loaded: true);
  }

  Future<CourseQuizAttempt?> bestFor(String itemId) async {
    await _ensureLoaded();
    return state.attempts[itemId];
  }

  /// Returns true when [score] beats the currently stored best for [itemId].
  Future<bool> isNewBest(String itemId, double score) async {
    final existing = await bestFor(itemId);
    if (existing == null) return true;
    return score > existing.score;
  }

  /// Keeps only the best-scored attempt: a lower/equal score is ignored.
  Future<void> saveBest(
    String itemId,
    CourseQuizAttempt attempt,
  ) async {
    await _ensureLoaded();
    final existing = state.attempts[itemId];
    if (existing != null && attempt.score <= existing.score) return;
    final updated = Map<String, CourseQuizAttempt>.from(state.attempts);
    updated[itemId] = attempt;
    state = CourseQuizAttemptsState(attempts: updated, loaded: true);
    await _persist(updated);
  }

  Future<void> _persist(Map<String, CourseQuizAttempt> attempts) async {
    final jsonMap = {
      for (final entry in attempts.entries) entry.key: entry.value.toJson(),
    };
    await _ref
        .read(storageProvider)
        .write(AppConstants.courseQuizAttemptsKey, json.encode(jsonMap));
  }
}

final courseQuizAttemptsProvider =
    StateNotifierProvider<CourseQuizAttemptsNotifier, CourseQuizAttemptsState>(
  (ref) => CourseQuizAttemptsNotifier(ref),
);