import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

final class GrammarExercise {
  final String id;
  final String sentence;
  final String category;
  final String topic;
  final bool isCorrect;
  final String explanation;
  final String? correctSentence;
  final int difficulty;
  final List<String> tags;
  final String? pairId;

  const GrammarExercise({
    required this.id,
    required this.sentence,
    required this.category,
    required this.topic,
    required this.isCorrect,
    required this.explanation,
    required this.correctSentence,
    required this.difficulty,
    required this.tags,
    required this.pairId,
  });

  factory GrammarExercise.fromJson(Map<String, dynamic> json) {
    return GrammarExercise(
      id: json['id'] as String,
      sentence: json['sentence'] as String,
      category: json['category'] as String,
      topic: json['topic'] as String,
      isCorrect: json['isCorrect'] as bool,
      explanation: json['explanation'] as String,
      correctSentence: json['correctSentence'] as String?,
      difficulty: (json['difficulty'] as num).toInt(),
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      pairId: json['pairId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sentence': sentence,
        'category': category,
        'topic': topic,
        'isCorrect': isCorrect,
        'explanation': explanation,
        'correctSentence': correctSentence,
        'difficulty': difficulty,
        'tags': tags,
        'pairId': pairId,
      };
}

final class GrammarContent {
  GrammarContent._();

  static List<GrammarExercise>? _cached;

  static Future<List<GrammarExercise>> load() async {
    if (_cached != null) return _cached!;
    final jsonString =
        await rootBundle.loadString('lib/content/grammar_exercises.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    _cached = jsonList
        .map((e) => GrammarExercise.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cached!;
  }

  static List<GrammarExercise> randomRound(int count) {
    final all = _cached;
    if (all == null || all.isEmpty) return [];

    final shuffled = List<GrammarExercise>.from(all);
    shuffled.shuffle(Random());

    final selected = <GrammarExercise>[];
    final usedPairIds = <String>{};
    final usedTopics = <String>{};
    var correctBudget = count ~/ 2;
    var incorrectBudget = count - correctBudget;

    for (final ex in shuffled) {
      if (selected.length >= count) break;

      if (ex.isCorrect && correctBudget <= 0) continue;
      if (!ex.isCorrect && incorrectBudget <= 0) continue;

      final pairId = ex.pairId;
      if (pairId != null && usedPairIds.contains(pairId)) continue;

      if (ex.isCorrect) {
        correctBudget--;
      } else {
        incorrectBudget--;
      }

      if (pairId != null) usedPairIds.add(pairId);
      if (ex.topic.isNotEmpty) usedTopics.add(ex.topic);

      selected.add(ex);
    }

    if (selected.length < count) {
      for (final ex in shuffled) {
        if (selected.length >= count) break;
        if (ex.pairId != null && usedPairIds.contains(ex.pairId)) continue;
        if (selected.contains(ex)) continue;

        if (ex.isCorrect) {
          correctBudget--;
        } else {
          incorrectBudget--;
        }
        final pid = ex.pairId;
        if (pid != null) usedPairIds.add(pid);

        selected.add(ex);
      }
    }

    selected.shuffle(Random());
    return selected.take(count).toList();
  }
}
