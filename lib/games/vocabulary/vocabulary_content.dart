import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../../content/difficulty_calibration.dart';
import '../../progress/user_progress.dart';

final class VocabularyExercise {
  final String id;
  final String word;
  final String partOfSpeech;
  final String definition;
  final String example;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String category;
  final List<String> synonyms;
  final int difficulty;

  const VocabularyExercise({
    required this.id,
    required this.word,
    required this.partOfSpeech,
    required this.definition,
    required this.example,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.category,
    required this.synonyms,
    required this.difficulty,
  });

  String get correctOption => options[correctOptionIndex];

  factory VocabularyExercise.fromJson(Map<String, dynamic> json) {
    return VocabularyExercise(
      id: json['id'] as String,
      word: json['word'] as String,
      partOfSpeech: json['partOfSpeech'] as String,
      definition: json['definition'] as String,
      example: json['example'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      correctOptionIndex: (json['correctOptionIndex'] as num).toInt(),
      explanation: json['explanation'] as String,
      category: json['category'] as String,
      synonyms: (json['synonyms'] as List<dynamic>).cast<String>(),
      difficulty: DifficultyCalibration.vocabulary(json['id'] as String),
    );
  }
}

final class VocabularyContent {
  VocabularyContent._();

  static List<VocabularyExercise>? _cached;

  static Future<List<VocabularyExercise>> load() async {
    if (_cached != null) return _cached!;

    final jsonString = await rootBundle.loadString(
      'lib/content/vocabulary_exercises.json',
    );
    final jsonList = json.decode(jsonString) as List<dynamic>;
    _cached = jsonList
        .map(
          (entry) => VocabularyExercise.fromJson(entry as Map<String, dynamic>),
        )
        .toList(growable: false);
    return _cached!;
  }

  static List<VocabularyExercise> randomRound(int count, {Random? random}) {
    final all = _cached;
    if (all == null || all.isEmpty || count <= 0) return [];

    final desiredCount = min(count, all.length);
    final generator = random ?? Random();
    final selected = <VocabularyExercise>[];
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

    if (selected.length < desiredCount) {
      final selectedIds = selected.map((exercise) => exercise.id).toSet();
      final remaining =
          all.where((exercise) => !selectedIds.contains(exercise.id)).toList()
            ..shuffle(generator);
      selected.addAll(remaining.take(desiredCount - selected.length));
    }

    return selected.toList(growable: false);
  }

  static List<VocabularyExercise> adaptiveRound(
    int count,
    GameProgress progress,
  ) {
    return AdaptiveRound.select(
      exercises: _cached ?? const [],
      count: count,
      progress: progress,
      idOf: (exercise) => exercise.id,
      difficultyOf: (exercise) => exercise.difficulty,
    );
  }
}
