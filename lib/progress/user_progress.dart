import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

final class ExerciseProgress {
  final int correctAnswers;
  final int incorrectAnswers;
  final int lastAnsweredAt;

  const ExerciseProgress({
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.lastAnsweredAt = 0,
  });

  int get attempts => correctAnswers + incorrectAnswers;
  bool get needsReview => incorrectAnswers > correctAnswers;

  ExerciseProgress record(bool isCorrect, int timestamp) {
    return ExerciseProgress(
      correctAnswers: correctAnswers + (isCorrect ? 1 : 0),
      incorrectAnswers: incorrectAnswers + (isCorrect ? 0 : 1),
      lastAnsweredAt: timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'correctAnswers': correctAnswers,
    'incorrectAnswers': incorrectAnswers,
    'lastAnsweredAt': lastAnsweredAt,
  };

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    return ExerciseProgress(
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      incorrectAnswers: json['incorrectAnswers'] as int? ?? 0,
      lastAnsweredAt: json['lastAnsweredAt'] as int? ?? 0,
    );
  }
}

final class GameProgress {
  final int skillScore;
  final Map<String, ExerciseProgress> exercises;

  const GameProgress({this.skillScore = 0, this.exercises = const {}});

  int get targetDifficulty {
    if (skillScore >= 24) return 5;
    if (skillScore >= 16) return 4;
    if (skillScore >= 9) return 3;
    if (skillScore >= 4) return 2;
    return 1;
  }

  GameProgress recordAnswer({
    required String exerciseId,
    required int difficulty,
    required bool isCorrect,
    required int timestamp,
  }) {
    final updatedExercises = Map<String, ExerciseProgress>.from(exercises);
    final progress = exercises[exerciseId] ?? const ExerciseProgress();
    updatedExercises[exerciseId] = progress.record(isCorrect, timestamp);
    final scoreChange = isCorrect ? difficulty : -difficulty * 2;

    return GameProgress(
      skillScore: (skillScore + scoreChange).clamp(-12, 30),
      exercises: updatedExercises,
    );
  }

  Map<String, dynamic> toJson() => {
    'skillScore': skillScore,
    'exercises': exercises.map(
      (id, progress) => MapEntry(id, progress.toJson()),
    ),
  };

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    final exercisesJson = json['exercises'] as Map<String, dynamic>? ?? {};
    return GameProgress(
      skillScore: json['skillScore'] as int? ?? 0,
      exercises: exercisesJson.map(
        (id, progress) => MapEntry(
          id,
          ExerciseProgress.fromJson(progress as Map<String, dynamic>),
        ),
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
    required String exerciseId,
    required int difficulty,
    required bool isCorrect,
    required int timestamp,
  }) {
    final updatedGames = Map<String, GameProgress>.from(games);
    updatedGames[gameId] = forGame(gameId).recordAnswer(
      exerciseId: exerciseId,
      difficulty: difficulty,
      isCorrect: isCorrect,
      timestamp: timestamp,
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
  static const _storageKey = 'user_progress_v1';

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
    required String exerciseId,
    required int difficulty,
    required bool isCorrect,
  }) async {
    _progress = _progress.recordAnswer(
      gameId: gameId,
      exerciseId: exerciseId,
      difficulty: difficulty,
      isCorrect: isCorrect,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await _preferences?.setString(_storageKey, _progress.toJson());
  }
}

final class AdaptiveRound {
  AdaptiveRound._();

  static List<T> select<T>({
    required Iterable<T> exercises,
    required int count,
    required GameProgress progress,
    required String Function(T exercise) idOf,
    required int Function(T exercise) difficultyOf,
    Random? random,
  }) {
    final all = exercises.toList();
    if (count <= 0 || all.isEmpty) return [];

    final generator = random ?? Random();
    final unseen = all
        .where((exercise) => !progress.exercises.containsKey(idOf(exercise)))
        .toList();
    final candidates = unseen.isNotEmpty ? unseen : all;
    candidates.shuffle(generator);
    final target = progress.targetDifficulty;
    candidates.sort((left, right) {
      final leftProgress = progress.exercises[idOf(left)];
      final rightProgress = progress.exercises[idOf(right)];
      final leftReview = leftProgress?.needsReview ?? false;
      final rightReview = rightProgress?.needsReview ?? false;
      if (leftReview != rightReview) return leftReview ? -1 : 1;

      final difficultyComparison = (difficultyOf(left) - target)
          .abs()
          .compareTo((difficultyOf(right) - target).abs());
      if (difficultyComparison != 0) return difficultyComparison;
      return (leftProgress?.lastAnsweredAt ?? 0).compareTo(
        rightProgress?.lastAnsweredAt ?? 0,
      );
    });
    return candidates
        .take(min(count, candidates.length))
        .toList(growable: false);
  }
}
