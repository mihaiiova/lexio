import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/content/hyphenation_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/grammar/grammar_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/idioms/idioms_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/spot/spot_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/vocabulary/vocabulary_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('explicit notionId is honored over derived identity', () {
    test('grammar exercise uses explicit notionId when present', () {
      final exercise = GrammarExercise.fromJson({
        'id': 'w0',
        'sentence': 'x',
        'category': 'c',
        'topic': 't',
        'isCorrect': false,
        'explanation': 'e',
        'correctSentence': 'y',
        'difficulty': 1,
        'tags': <String>[],
        'pairId': 'p0',
        'notionId': 'permanent-id',
      });

      expect(exercise.notionId, 'permanent-id');
    });

    test('grammar exercise falls back to pairId without explicit notionId', () {
      final exercise = GrammarExercise.fromJson({
        'id': 'w0',
        'sentence': 'x',
        'category': 'c',
        'topic': 't',
        'isCorrect': false,
        'explanation': 'e',
        'correctSentence': 'y',
        'difficulty': 1,
        'tags': <String>[],
        'pairId': 'p0',
      });

      expect(exercise.notionId, 'p0');
    });

    test('vocabulary exercise uses explicit notionId when present', () {
      final exercise = VocabularyExercise.fromJson({
        'id': 'v001',
        'word': 'curios',
        'partOfSpeech': 'adjectiv',
        'definition': 'd',
        'example': 'e',
        'options': ['a', 'b'],
        'correctOptionIndex': 0,
        'explanation': 'e',
        'category': 'c',
        'synonyms': <String>[],
        'notionId': 'permanent-id',
      });

      expect(exercise.notionId, 'permanent-id');
    });

    test('idiom exercise uses explicit notionId when present', () {
      final exercise = IdiomExercise.fromJson({
        'id': 'i001',
        'expression': 'a bate apa-n piuă',
        'meaning': 'm',
        'example': 'e',
        'highlightedText': 'h',
        'options': ['a', 'b'],
        'correctOptionIndex': 0,
        'category': 'c',
        'difficulty': 1,
        'notionId': 'permanent-id',
      });

      expect(exercise.notionId, 'permanent-id');
    });

    test('spot mistake uses explicit notionId when present', () {
      final mistake = SpotMistake.fromJson({
        'wordIndex': 0,
        'token': 'bări',
        'replacement': 'bare',
        'explanation': 'e',
        'category': 'c',
        'topic': 't',
        'commonErrorPairIndex': 0,
        'notionId': 'permanent-id',
      });

      expect(mistake.notionId, 'permanent-id');
    });

    test('spot mistake falls back to derived identity without notionId', () {
      final commonError = SpotMistake.fromJson({
        'wordIndex': 0,
        'token': 'bări',
        'replacement': 'bare',
        'explanation': 'e',
        'category': 'c',
        'topic': 't',
        'commonErrorPairIndex': 3,
      });
      final hyphenation = SpotMistake.fromJson({
        'wordIndex': 0,
        'token': 'sa',
        'replacement': 's-a',
        'explanation': 'e',
        'category': 'c',
        'topic': 't',
        'hyphenationPairId': 's_a_sa',
      });

      expect(commonError.notionId, 'gp3');
      expect(
        hyphenation.notionId,
        'sp_${Uri.encodeComponent('sa')}_${Uri.encodeComponent('s-a')}',
      );
    });
  });

  group('bundled canonical content carries explicit notionId', () {
    Future<List<dynamic>> loadJsonList(String path) async {
      final raw = await rootBundle.loadString(path);
      return json.decode(raw) as List<dynamic>;
    }

    test('grammar explicit notionIds equal the derived pair identity', () async {
      final raw = await loadJsonList('lib/content/grammar_exercises.json');
      final exercises = await GrammarContent.load();

      for (final entry in raw.cast<Map<String, dynamic>>()) {
        final id = entry['id'] as String;
        final explicit = entry['notionId'];
        expect(explicit, isNotNull, reason: 'grammar $id missing notionId');
        expect(explicit, isNotEmpty, reason: 'grammar $id empty notionId');

        final model = exercises.firstWhere((e) => e.id == id);
        expect(entry['notionId'], model.notionId, reason: id);
      }
    });

    test('vocabulary explicit notionIds equal the derived word identity',
        () async {
      final raw = await loadJsonList('lib/content/vocabulary_exercises.json');
      final exercises = await VocabularyContent.load();

      for (final entry in raw.cast<Map<String, dynamic>>()) {
        final id = entry['id'] as String;
        expect(entry['notionId'], isNotNull, reason: 'vocab $id');
        expect(entry['notionId'], entry['word'], reason: id);

        final model = exercises.firstWhere((e) => e.id == id);
        expect(entry['notionId'], model.notionId, reason: id);
      }
    });

    test('idiom explicit notionIds equal the derived expression identity',
        () async {
      final raw = await loadJsonList('lib/content/idiom_exercises.json');
      final exercises = await IdiomsContent.load();

      for (final entry in raw.cast<Map<String, dynamic>>()) {
        final id = entry['id'] as String;
        expect(entry['notionId'], isNotNull, reason: 'idiom $id');
        expect(entry['notionId'], entry['expression'], reason: id);

        final model = exercises.firstWhere((e) => e.id == id);
        expect(entry['notionId'], model.notionId, reason: id);
      }
    });

    test('spot mistake explicit notionIds equal the derived identity',
        () async {
      final raw = await loadJsonList('lib/content/spot_texts.json');
      final texts = await SpotContent.load();

      for (final text in raw.cast<Map<String, dynamic>>()) {
        final id = text['id'] as String;
        final mistakes = (text['mistakes'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final model = texts.firstWhere((t) => t.id == id);

        for (var i = 0; i < mistakes.length; i++) {
          final mistake = mistakes[i];
          final explicit = mistake['notionId'];
          expect(
            explicit,
            isNotNull,
            reason: '$id mistake $i missing notionId',
          );
          expect(
            explicit,
            model.mistakes[i].notionId,
            reason: '$id mistake $i',
          );
        }
      }
    });

    test('common error pairs carry the shared gp index identity', () async {
      final raw = await loadJsonList('data/common_error_pairs.json');
      for (var i = 0; i < raw.length; i++) {
        final entry = raw[i] as Map<String, dynamic>;
        expect(entry['notionId'], 'gp$i', reason: 'common error $i');
      }
    });

    test('hyphenation pairs carry the hyphenated grammar identity', () async {
      final raw = await loadJsonList('data/hyphenation_pairs.json');
      final pairs = await HyphenationContent.load();

      for (final entry in raw.cast<Map<String, dynamic>>()) {
        final id = entry['id'] as String;
        expect(
          entry['notionId'],
          'hyphenated_$id',
          reason: 'hyphenation $id',
        );
        expect(
          pairs.any((p) => p.id == id),
          isTrue,
          reason: 'hyphenation $id must still parse',
        );
      }
    });
  });
}
