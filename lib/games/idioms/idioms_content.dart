import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../../content/difficulty_calibration.dart';
import '../../progress/user_progress.dart';

final class IdiomExercise {
  final String id;
  final String expression;
  final String meaning;
  final String example;
  final String highlightedText;
  final List<String> options;
  final int correctOptionIndex;
  final String category;
  final int difficulty;

  const IdiomExercise({
    required this.id,
    required this.expression,
    required this.meaning,
    required this.example,
    required this.highlightedText,
    required this.options,
    required this.correctOptionIndex,
    required this.category,
    required this.difficulty,
  });

  factory IdiomExercise.fromJson(Map<String, dynamic> json) {
    return IdiomExercise(
      id: json['id'] as String,
      expression: json['expression'] as String,
      meaning: json['meaning'] as String,
      example: json['example'] as String,
      highlightedText: json['highlightedText'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      correctOptionIndex: (json['correctOptionIndex'] as num).toInt(),
      category: json['category'] as String,
      difficulty: DifficultyCalibration.idiom(json['id'] as String),
    );
  }
}

final class IdiomsContent {
  IdiomsContent._();

  static List<IdiomExercise>? _cached;

  static Future<List<IdiomExercise>> load() async {
    if (_cached != null) return _cached!;

    final jsonString = await rootBundle.loadString(
      'lib/content/idiom_exercises.json',
    );
    final jsonList = json.decode(jsonString) as List<dynamic>;
    _cached = jsonList
        .map((entry) => IdiomExercise.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
    return _cached!;
  }

  static List<IdiomExercise> randomRound(int count, {Random? random}) {
    final all = _cached;
    if (all == null || all.isEmpty || count <= 0) return [];

    final desiredCount = min(count, all.length);
    final generator = random ?? Random();
    final selected = <IdiomExercise>[];
    const difficultyLevels = [1, 2, 3, 4, 5];

    for (var index = 0; index < difficultyLevels.length; index++) {
      final candidates =
          all
              .where(
                (exercise) => exercise.difficulty == difficultyLevels[index],
              )
              .toList()
            ..shuffle(generator);
      final levelCount =
          desiredCount ~/ difficultyLevels.length +
          (index < desiredCount % difficultyLevels.length ? 1 : 0);
      selected.addAll(candidates.take(levelCount));
    }

    return selected.toList(growable: false);
  }

  static List<IdiomExercise> adaptiveRound(int count, GameProgress progress) {
    return AdaptiveRound.select(
      exercises: _cached ?? const [],
      count: count,
      progress: progress,
      idOf: (exercise) => exercise.id,
      difficultyOf: (exercise) => exercise.difficulty,
    );
  }
}
