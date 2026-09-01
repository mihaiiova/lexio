import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'learning_item.dart';

int _todayDay() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

final class GameProgress {
  final Map<String, LearningItem> items;

  const GameProgress({this.items = const {}});

  LearningItem progressFor(String notionId) =>
      items[notionId] ?? LearningItem.newItem(notionId: notionId);

  int countOverdue(int today) =>
      items.values.where((item) => item.isOverdue(today)).length;

  int countEligible(int today) =>
      items.values.where((item) => item.isEligibleForReview(today)).length;

  int countMastered() =>
      items.values.where((item) => item.state == LearningItemState.mastered).length;

  GameProgress recordAnswer({
    required String notionId,
    required bool isCorrect,
    required int today,
  }) {
    final current = items[notionId] ?? LearningItem.newItem(notionId: notionId);
    final updated = current.recordAnswer(isCorrect: isCorrect, today: today);
    final updatedItems = Map<String, LearningItem>.from(items);
    updatedItems[notionId] = updated;
    return GameProgress(items: updatedItems);
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((id, item) => MapEntry(id, item.toJson())),
  };

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as Map<String, dynamic>? ?? {};
    return GameProgress(
      items: itemsJson.map(
        (id, data) =>
            MapEntry(id, LearningItem.fromJson(data as Map<String, dynamic>)),
      ),
    );
  }
}

final class UserProgress {
  final Map<String, GameProgress> games;

  const UserProgress({this.games = const {}});

  GameProgress forGame(String gameId) => games[gameId] ?? const GameProgress();

  UserProgress recordAnswer({
    required String gameId,
    required String notionId,
    required bool isCorrect,
    required int today,
  }) {
    final updatedGames = Map<String, GameProgress>.from(games);
    updatedGames[gameId] = forGame(
      gameId,
    ).recordAnswer(notionId: notionId, isCorrect: isCorrect, today: today);
    return UserProgress(games: updatedGames);
  }

  String toJson() => jsonEncode({
    'games': games.map((id, progress) => MapEntry(id, progress.toJson())),
  });

  factory UserProgress.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final gamesJson = json['games'] as Map<String, dynamic>? ?? {};
    return UserProgress(
      games: gamesJson.map(
        (id, progress) => MapEntry(
          id,
          GameProgress.fromJson(progress as Map<String, dynamic>),
        ),
      ),
    );
  }
}

abstract interface class ProgressStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

final class SharedPreferencesProgressStorage implements ProgressStorage {
  final SharedPreferencesAsync _preferences;

  SharedPreferencesProgressStorage(this._preferences);

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

final class ProgressRepository {
  static const _storageKey = 'user_progress_v2';

  ProgressRepository({
    ProgressStorage? storage,
    UserProgress progress = const UserProgress(),
  }) : this._(storage: storage, progress: progress);

  ProgressRepository._({this._storage, required this._progress});

  final ProgressStorage? _storage;
  UserProgress _progress;
  Future<void> _pendingWrite = Future<void>.value();

  static Future<ProgressRepository> load({ProgressStorage? storage}) async {
    try {
      final effectiveStorage =
          storage ?? SharedPreferencesProgressStorage(SharedPreferencesAsync());
      final source = await effectiveStorage.read(_storageKey);
      final progress = source == null
          ? const UserProgress()
          : UserProgress.fromJson(source);
      return ProgressRepository(storage: effectiveStorage, progress: progress);
    } catch (_) {
      return ProgressRepository();
    }
  }

  GameProgress forGame(String gameId) => _progress.forGame(gameId);

  Future<void> recordAnswer({
    required String gameId,
    required String notionId,
    required bool isCorrect,
  }) {
    final today = _todayDay();
    _progress = _progress.recordAnswer(
      gameId: gameId,
      notionId: notionId,
      isCorrect: isCorrect,
      today: today,
    );
    return _enqueueWrite();
  }

  Future<void> recordAnswers({
    required String gameId,
    required Map<String, bool> notionResults,
  }) {
    final today = _todayDay();
    var updated = _progress;
    for (final entry in notionResults.entries) {
      updated = updated.recordAnswer(
        gameId: gameId,
        notionId: entry.key,
        isCorrect: entry.value,
        today: today,
      );
    }
    _progress = updated;
    return _enqueueWrite();
  }

  Future<void> _enqueueWrite() {
    final snapshot = _progress.toJson();
    _pendingWrite = _pendingWrite.then((_) => _writeSnapshot(snapshot));
    return _pendingWrite;
  }

  Future<void> _writeSnapshot(String snapshot) async {
    try {
      await _storage?.write(_storageKey, snapshot);
    } catch (error) {
      debugPrint('ProgressRepository: failed to persist progress: $error');
    }
  }
}

final class RoundSelector {
  RoundSelector._();

  static List<T> select<T>({
    required List<T> exercises,
    required int count,
    required GameProgress progress,
    required String Function(T exercise) notionIdOf,
    int Function(T exercise)? difficultyOf,
    Random? random,
    int? today,
  }) {
    if (count <= 0 || exercises.isEmpty) return [];

    final effectiveToday = today ?? _todayDay();
    final selected = <T>[];
    final usedNotions = <String>{};

    final overdue = <T>[];
    final newItems = <T>[];
    final ineligible = <T>[];

    for (final exercise in exercises) {
      final notionId = notionIdOf(exercise);
      final item = progress.progressFor(notionId);
      if (item.isOverdue(effectiveToday)) {
        overdue.add(exercise);
      } else if (item.state == LearningItemState.newItem) {
        newItems.add(exercise);
      } else {
        ineligible.add(exercise);
      }
    }

    _sortBucket(overdue, difficultyOf, notionIdOf);
    _sortBucket(newItems, difficultyOf, notionIdOf);
    _sortBucket(ineligible, difficultyOf, notionIdOf);

    final overdueQuota = newItems.isNotEmpty ? count - 1 : count;

    _addFromBucket(overdue, selected, usedNotions, notionIdOf, overdueQuota);
    _addFromBucket(newItems, selected, usedNotions, notionIdOf, count);
    _addFromBucket(ineligible, selected, usedNotions, notionIdOf, count);

    if (selected.isEmpty && exercises.isNotEmpty) {
      return [exercises.first];
    }

    return selected.toList(growable: false);
  }

  static List<T> selectMultiNotion<T>({
    required List<T> exercises,
    required int count,
    required GameProgress progress,
    required List<String> Function(T exercise) notionIdsOf,
    int Function(T exercise)? difficultyOf,
    Random? random,
    int? today,
  }) {
    if (count <= 0 || exercises.isEmpty) return [];

    final effectiveToday = today ?? _todayDay();
    final selected = <T>[];
    final usedNotions = <String>{};

    final overdue = <T>[];
    final newItems = <T>[];
    final ineligible = <T>[];

    for (final exercise in exercises) {
      final notions = notionIdsOf(exercise);
      final items = notions.map((n) => progress.progressFor(n)).toList();

      final anyOverdue = items.any((item) => item.isOverdue(effectiveToday));
      final anyNew = items.any(
        (item) => item.state == LearningItemState.newItem,
      );

      if (anyOverdue) {
        overdue.add(exercise);
      } else if (anyNew) {
        newItems.add(exercise);
      } else {
        ineligible.add(exercise);
      }
    }

    String notionKeyOf(T exercise) {
      final notions = notionIdsOf(exercise);
      if (notions.isEmpty) return '';
      final sorted = List<String>.from(notions)..sort();
      return sorted.join('\u0000');
    }

    _sortBucket(overdue, difficultyOf, notionKeyOf);
    _sortBucket(newItems, difficultyOf, notionKeyOf);
    _sortBucket(ineligible, difficultyOf, notionKeyOf);

    final overdueQuota = newItems.isNotEmpty ? count - 1 : count;

    _addFromBucketMulti(
      overdue,
      selected,
      usedNotions,
      notionIdsOf,
      overdueQuota,
    );
    _addFromBucketMulti(newItems, selected, usedNotions, notionIdsOf, count);
    _addFromBucketMulti(
      ineligible,
      selected,
      usedNotions,
      notionIdsOf,
      count,
    );

    if (selected.isEmpty && exercises.isNotEmpty) {
      return [exercises.first];
    }

    return selected.toList(growable: false);
  }

  static void _sortBucket<T>(
    List<T> bucket,
    int Function(T)? difficultyOf,
    String Function(T) notionKeyOf,
  ) {
    bucket.sort((a, b) {
      final byDifficulty = (difficultyOf?.call(a) ?? 0).compareTo(
        difficultyOf?.call(b) ?? 0,
      );
      if (byDifficulty != 0) return byDifficulty;
      return notionKeyOf(a).compareTo(notionKeyOf(b));
    });
  }

  static void _addFromBucket<T>(
    List<T> bucket,
    List<T> selected,
    Set<String> usedNotions,
    String Function(T) notionIdOf,
    int targetCount,
  ) {
    if (selected.length >= targetCount) return;
    for (final exercise in bucket) {
      if (selected.length >= targetCount) break;
      final notionId = notionIdOf(exercise);
      if (usedNotions.contains(notionId)) continue;
      selected.add(exercise);
      usedNotions.add(notionId);
    }
  }

  static void _addFromBucketMulti<T>(
    List<T> bucket,
    List<T> selected,
    Set<String> usedNotions,
    List<String> Function(T) notionIdsOf,
    int targetCount,
  ) {
    if (selected.length >= targetCount) return;
    for (final exercise in bucket) {
      if (selected.length >= targetCount) break;
      final notions = notionIdsOf(exercise);
      if (notions.any((n) => usedNotions.contains(n))) continue;
      selected.add(exercise);
      usedNotions.addAll(notions);
    }
  }
}
