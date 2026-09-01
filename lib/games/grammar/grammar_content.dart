import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../../content/hyphenation_content.dart';
import '../../content/difficulty_calibration.dart';
import '../../design/doom.dart';
import '../../progress/user_progress.dart';

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
  final String? doomWord;
  final String? doomDefinition;
  final String? hyphenationPairId;

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
    this.doomWord,
    this.doomDefinition,
    this.hyphenationPairId,
  });

  String get notionId => pairId ?? id;

  String? get doomUrl => doomWord != null ? DoomUrl.forWord(doomWord!) : null;

  factory GrammarExercise.fromJson(Map<String, dynamic> json) {
    return GrammarExercise(
      id: json['id'] as String,
      sentence: json['sentence'] as String,
      category: json['category'] as String,
      topic: json['topic'] as String,
      isCorrect: json['isCorrect'] as bool,
      explanation: json['explanation'] as String,
      correctSentence: json['correctSentence'] as String?,
      difficulty: DifficultyCalibration.grammar(
        json['id'] as String,
        (json['difficulty'] as num).toInt(),
      ),
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      pairId: json['pairId'] as String?,
      doomWord: json['doomWord'] as String?,
      doomDefinition: json['doomDefinition'] as String?,
      hyphenationPairId: json['hyphenationPairId'] as String?,
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
    'doomWord': doomWord,
    'doomDefinition': doomDefinition,
    'hyphenationPairId': hyphenationPairId,
  };
}

final class GrammarContent {
  GrammarContent._();

  static List<GrammarExercise>? _cached;

  static Future<List<GrammarExercise>> load() async {
    if (_cached != null) return _cached!;
    final jsonString = await rootBundle.loadString(
      'lib/content/grammar_exercises.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    final hyphenationPairs = await HyphenationContent.load();
    _cached = [
      ...jsonList.map(
        (entry) => GrammarExercise.fromJson(entry as Map<String, dynamic>),
      ),
      ..._buildHyphenationExercises(hyphenationPairs),
    ];
    return _cached!;
  }

  static Iterable<GrammarExercise> _buildHyphenationExercises(
    List<HyphenationPair> pairs,
  ) sync* {
    for (final pair in pairs) {
      final hyphenatedPairId = 'hyphenated_${pair.id}';
      final difficulty = pair.unhyphenatedIsValid ? 3 : 2;
      yield GrammarExercise(
        id: '${hyphenatedPairId}_wrong',
        sentence: pair.missingHyphenExample,
        category: 'cratimă',
        topic: 'cratima',
        isCorrect: false,
        explanation: pair.hyphenatedExplanation,
        correctSentence: pair.hyphenatedExample,
        difficulty: difficulty,
        tags: const ['cratimă', 'greșeală frecventă'],
        pairId: hyphenatedPairId,
        hyphenationPairId: pair.id,
      );
      yield GrammarExercise(
        id: '${hyphenatedPairId}_correct',
        sentence: pair.hyphenatedExample,
        category: 'cratimă',
        topic: 'cratima',
        isCorrect: true,
        explanation: 'Propoziția este corectă. ${pair.hyphenatedExplanation}',
        correctSentence: null,
        difficulty: difficulty,
        tags: const ['cratimă', 'confirmare'],
        pairId: hyphenatedPairId,
        hyphenationPairId: pair.id,
      );

      final unnecessaryHyphenExample = pair.unnecessaryHyphenExample;
      final unhyphenatedExample = pair.unhyphenatedExample;
      final unhyphenatedExplanation = pair.unhyphenatedExplanation;
      if (unnecessaryHyphenExample == null ||
          unhyphenatedExample == null ||
          unhyphenatedExplanation == null) {
        continue;
      }

      final unhyphenatedPairId = 'unhyphenated_${pair.id}';
      final explanation =
          'În acest context, „${pair.unhyphenatedForm}” se scrie fără cratimă. '
          '$unhyphenatedExplanation';
      yield GrammarExercise(
        id: '${unhyphenatedPairId}_wrong',
        sentence: unnecessaryHyphenExample,
        category: 'cratimă',
        topic: 'cratima',
        isCorrect: false,
        explanation: explanation,
        correctSentence: unhyphenatedExample,
        difficulty: 3,
        tags: const ['cratimă', 'forme omofone', 'greșeală frecventă'],
        pairId: unhyphenatedPairId,
        hyphenationPairId: pair.id,
      );
      yield GrammarExercise(
        id: '${unhyphenatedPairId}_correct',
        sentence: unhyphenatedExample,
        category: 'cratimă',
        topic: 'cratima',
        isCorrect: true,
        explanation: 'Propoziția este corectă. $explanation',
        correctSentence: null,
        difficulty: 3,
        tags: const ['cratimă', 'forme omofone', 'confirmare'],
        pairId: unhyphenatedPairId,
        hyphenationPairId: pair.id,
      );
    }
  }

  static Set<String> distinctNotionIds() =>
      (_cached ?? const []).map((e) => e.notionId).toSet();

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

  static List<GrammarExercise> adaptiveRound(int count, GameProgress progress) {
    return RoundSelector.select(
      exercises: _cached ?? const [],
      count: count,
      progress: progress,
      notionIdOf: (exercise) => exercise.notionId,
    );
  }
}
