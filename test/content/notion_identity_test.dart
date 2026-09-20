import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/games/grammar/grammar_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/idioms/idioms_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/spot/spot_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/vocabulary/vocabulary_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/user_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every bundled exercise and mistake exposes a non-empty notion id',
    () async {
      final grammar = await GrammarContent.load();
      final idioms = await IdiomsContent.load();
      final vocabulary = await VocabularyContent.load();
      final spot = await SpotContent.load();

      for (final exercise in grammar) {
        expect(exercise.notionId, isNotEmpty, reason: exercise.id);
      }
      for (final exercise in idioms) {
        expect(exercise.notionId, isNotEmpty, reason: exercise.id);
      }
      for (final exercise in vocabulary) {
        expect(exercise.notionId, isNotEmpty, reason: exercise.id);
      }
      for (final text in spot) {
        expect(text.mistakeNotionIds, isNotEmpty, reason: text.id);
        for (final mistake in text.mistakes) {
          expect(
            mistake.notionId,
            isNotEmpty,
            reason: '${text.id}:${mistake.token}',
          );
        }
      }
    },
  );

  test('vocabulary and idiom notions are unique across the corpus', () async {
    final idioms = await IdiomsContent.load();
    final vocabulary = await VocabularyContent.load();

    expect(
      idioms.map((exercise) => exercise.notionId).toSet(),
      hasLength(idioms.length),
    );
    expect(
      vocabulary.map((exercise) => exercise.notionId).toSet(),
      hasLength(vocabulary.length),
    );
  });

  test(
    'grammar exercises sharing a notion never span multiple topics',
    () async {
      final grammar = await GrammarContent.load();

      final topicsByNotion = <String, Set<String>>{};
      for (final exercise in grammar) {
        topicsByNotion
            .putIfAbsent(exercise.notionId, () => <String>{})
            .add(exercise.topic);
      }

      for (final entry in topicsByNotion.entries) {
        expect(
          entry.value,
          hasLength(1),
          reason: 'notion ${entry.key} spans multiple topics: ${entry.value}',
        );
      }
    },
    skip:
        'blocked by GitHub issue #49: grammar pairId "p186" spans vocativ + '
        'pluralul substantivelor',
  );

  test(
    'spot text mistakes never share a notion within a single text',
    () async {
      final spot = await SpotContent.load();

      for (final text in spot) {
        final notions = text.mistakeNotionIds;
        expect(
          notions.toSet(),
          hasLength(notions.length),
          reason: '${text.id} reuses a mistake notion: $notions',
        );
      }
    },
    skip:
        'blocked by GitHub issue #50: text_051 reuses '
        'commonErrorPairIndex 186 for both "Aceiași" and "comfort"',
  );

  test('adaptive rounds never serve duplicate notions', () async {
    await GrammarContent.load();
    await VocabularyContent.load();
    await IdiomsContent.load();
    await SpotContent.load();

    final grammarRound = GrammarContent.adaptiveRound(15, const GameProgress());
    expect(grammarRound, hasLength(15));
    expect(
      grammarRound.map((exercise) => exercise.notionId).toSet(),
      hasLength(grammarRound.length),
    );

    final vocabularyRound = VocabularyContent.adaptiveRound(
      10,
      const GameProgress(),
    );
    expect(vocabularyRound, hasLength(10));
    expect(
      vocabularyRound.map((exercise) => exercise.notionId).toSet(),
      hasLength(vocabularyRound.length),
    );

    final idiomsRound = IdiomsContent.adaptiveRound(10, const GameProgress());
    expect(idiomsRound, hasLength(10));
    expect(
      idiomsRound.map((exercise) => exercise.notionId).toSet(),
      hasLength(idiomsRound.length),
    );

    final spotSession = SpotContent.adaptiveSession(5, const GameProgress());
    expect(spotSession, hasLength(5));
    final usedNotions = <String>{};
    for (final text in spotSession) {
      for (final notion in text.mistakeNotionIds.toSet()) {
        expect(usedNotions.contains(notion), isFalse, reason: notion);
        usedNotions.add(notion);
      }
    }
  });
}
