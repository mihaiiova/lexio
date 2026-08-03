import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'learning_item.dart';

int _todayDay() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day)
          .millisecondsSinceEpoch ~/
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
        (id, data) => MapEntry(
          id,
          LearningItem.fromJson(data as Map<String, dynamic>),
        ),
      ),
    );
  }
}

final class UserProgress {
  final Map<String, GameProgress> games;

  const UserProgress({this.games = const {}});

  GameProgress forGame(String gameId) =>
      games[gameId] ?? const GameProgress();

  UserProgress recordAnswer({
    required String gameId,
    required String notionId,
    required bool isCorrect,
    required int today,
  }) {
    final updatedGames = Map<String, GameProgress>.from(games);
    updatedGames[gameId] = forGame(gameId).recordAnswer(
      notionId: notionId,
      isCorrect: isCorrect,
      today: today,
    );
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

final class ProgressRepository {
  static const _storageKey = 'user_progress_v2';

  ProgressRepository._(this._preferences, this._progress);

  final SharedPreferencesAsync? _preferences;
  UserProgress _progress;

  static Future<ProgressRepository> load() async {
    SharedPreferencesAsync? preferences;
    UserProgress progress;
    try {
      preferences = SharedPreferencesAsync();
      final source = await preferences.getString(_storageKey);
      progress = source == null
          ? const UserProgress()
          : UserProgress.fromJson(source);
    } catch (_) {
      preferences = null;
      progress = const UserProgress();
    }
    return ProgressRepository._(preferences, progress);
  }

  GameProgress forGame(String gameId) => _progress.forGame(gameId);

  Future<void> recordAnswer({
    required String gameId,
    required String notionId,
    required bool isCorrect,
  }) async {
    final today = _todayDay();
    _progress = _progress.recordAnswer(
      gameId: gameId,
      notionId: notionId,
      isCorrect: isCorrect,
      today: today,
    );
    await _preferences?.setString(_storageKey, _progress.toJson());
  }

  Future<void> recordAnswers({
    required String gameId,
    required Map<String, bool> notionResults,
  }) async {
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
    await _preferences?.setString(_storageKey, _progress.toJson());
  }
}

final class RoundSelector {
  RoundSelector._();

  static List<T> select<T>({
    required List<T> exercises,
    required int count,
    required GameProgress progress,
    required String Function(T exercise) notionIdOf,
    Random? random,
    int? today,
  }) {
    if (count <= 0 || exercises.isEmpty) return [];

    final generator = random ?? Random();
    final effectiveToday = today ?? _todayDay();
    final selected = <T>[];
    final usedNotions = <String>{};

    final shuffled = List<T>.from(exercises)..shuffle(generator);

    final overdue = <T>[];
    final eligible = <T>[];
    final newItems = <T>[];
    final ineligible = <T>[];

    for (final exercise in shuffled) {
      final notionId = notionIdOf(exercise);
      final item = progress.progressFor(notionId);
      if (item.isOverdue(effectiveToday)) {
        overdue.add(exercise);
      } else if (item.state == LearningItemState.newItem) {
        newItems.add(exercise);
      } else if (item.isEligibleForReview(effectiveToday)) {
        eligible.add(exercise);
      } else {
        ineligible.add(exercise);
      }
    }

    _addFromBucket(overdue, selected, usedNotions, notionIdOf, count, generator);
    _addFromBucket(
      eligible,
      selected,
      usedNotions,
      notionIdOf,
      count,
      generator,
    );
    _addFromBucket(
      newItems,
      selected,
      usedNotions,
      notionIdOf,
      count,
      generator,
    );
    _addFromBucket(
      ineligible,
      selected,
      usedNotions,
      notionIdOf,
      count,
      generator,
    );

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
    Random? random,
    int? today,
  }) {
    if (count <= 0 || exercises.isEmpty) return [];

    final generator = random ?? Random();
    final effectiveToday = today ?? _todayDay();
    final selected = <T>[];
    final usedNotions = <String>{};

    final shuffled = List<T>.from(exercises)..shuffle(generator);

    final overdue = <T>[];
    final eligible = <T>[];
    final newItems = <T>[];
    final ineligible = <T>[];

    for (final exercise in shuffled) {
      final notions = notionIdsOf(exercise);
      final items = notions.map((n) => progress.progressFor(n)).toList();

      final anyOverdue =
          items.any((item) => item.isOverdue(effectiveToday));
      final anyNew =
          items.any((item) => item.state == LearningItemState.newItem);
      final anyEligible =
          items.any((item) => item.isEligibleForReview(effectiveToday));

      if (anyOverdue) {
        overdue.add(exercise);
      } else if (anyNew) {
        newItems.add(exercise);
      } else if (anyEligible) {
        eligible.add(exercise);
      } else {
        ineligible.add(exercise);
      }
    }

    _addFromBucketMulti(
      overdue,
      selected,
      usedNotions,
      notionIdsOf,
      count,
      generator,
    );
    _addFromBucketMulti(
      eligible,
      selected,
      usedNotions,
      notionIdsOf,
      count,
      generator,
    );
    _addFromBucketMulti(
      newItems,
      selected,
      usedNotions,
      notionIdsOf,
      count,
      generator,
    );
    _addFromBucketMulti(
      ineligible,
      selected,
      usedNotions,
      notionIdsOf,
      count,
      generator,
    );

    if (selected.isEmpty && exercises.isNotEmpty) {
      return [exercises.first];
    }

    return selected.toList(growable: false);
  }

  static void _addFromBucket<T>(
    List<T> bucket,
    List<T> selected,
    Set<String> usedNotions,
    String Function(T) notionIdOf,
    int targetCount,
    Random generator,
  ) {
    if (selected.length >= targetCount) return;
    final shuffled = List<T>.from(bucket)..shuffle(generator);
    for (final exercise in shuffled) {
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
    Random generator,
  ) {
    if (selected.length >= targetCount) return;
    final shuffled = List<T>.from(bucket)..shuffle(generator);
    for (final exercise in shuffled) {
      if (selected.length >= targetCount) break;
      final notions = notionIdsOf(exercise);
      if (notions.any((n) => usedNotions.contains(n))) continue;
      selected.add(exercise);
      usedNotions.addAll(notions);
    }
  }
}
