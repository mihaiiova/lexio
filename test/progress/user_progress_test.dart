import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/progress/learning_item.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/user_progress.dart';

void main() {
  group('LearningItem state transitions', () {
    test('newItem -> learning on correct, next review +1 day', () {
      const item = LearningItem.newItem(notionId: 'notion_a');
      final updated = item.recordAnswer(isCorrect: true, today: 100);

      expect(updated.state, LearningItemState.learning);
      expect(updated.nextReviewDay, 101);
    });

    test('newItem -> learning on incorrect, next review +1 day', () {
      const item = LearningItem.newItem(notionId: 'notion_a');
      final updated = item.recordAnswer(isCorrect: false, today: 100);

      expect(updated.state, LearningItemState.learning);
      expect(updated.nextReviewDay, 101);
    });

    test('learning -> consolidating on correct, next review +3 days', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.learning,
        step: -1,
        nextReviewDay: 100,
        lastAnsweredDay: 99,
      );
      final updated = item.recordAnswer(isCorrect: true, today: 100);

      expect(updated.state, LearningItemState.consolidating);
      expect(updated.step, LearningItem.consolidating3d);
      expect(updated.nextReviewDay, 103);
    });

    test('learning -> stays learning on incorrect, next review +1 day', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.learning,
        step: -1,
        nextReviewDay: 100,
        lastAnsweredDay: 99,
      );
      final updated = item.recordAnswer(isCorrect: false, today: 100);

      expect(updated.state, LearningItemState.learning);
      expect(updated.nextReviewDay, 101);
    });

    test(
      'consolidating step 0 -> step 1 on correct, next review +7 days',
      () {
        const item = LearningItem(
          notionId: 'notion_a',
          state: LearningItemState.consolidating,
          step: LearningItem.consolidating3d,
          nextReviewDay: 100,
          lastAnsweredDay: 97,
        );
        final updated = item.recordAnswer(isCorrect: true, today: 100);

        expect(updated.state, LearningItemState.consolidating);
        expect(updated.step, LearningItem.consolidating7d);
        expect(updated.nextReviewDay, 107);
      },
    );

    test(
      'consolidating step 1 -> step 2 on correct, next review +21 days',
      () {
        const item = LearningItem(
          notionId: 'notion_a',
          state: LearningItemState.consolidating,
          step: LearningItem.consolidating7d,
          nextReviewDay: 100,
          lastAnsweredDay: 93,
        );
        final updated = item.recordAnswer(isCorrect: true, today: 100);

        expect(updated.state, LearningItemState.consolidating);
        expect(updated.step, LearningItem.consolidating21d);
        expect(updated.nextReviewDay, 121);
      },
    );

    test('consolidating step 2 -> mastered on correct, next review +60 days',
        () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.consolidating,
        step: LearningItem.consolidating21d,
        nextReviewDay: 100,
        lastAnsweredDay: 79,
      );
      final updated = item.recordAnswer(isCorrect: true, today: 100);

      expect(updated.state, LearningItemState.mastered);
      expect(updated.step, LearningItem.mastered60d);
      expect(updated.nextReviewDay, 160);
    });

    test('consolidating -> learning on incorrect, next review +1 day', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.consolidating,
        step: LearningItem.consolidating7d,
        nextReviewDay: 100,
        lastAnsweredDay: 93,
      );
      final updated = item.recordAnswer(isCorrect: false, today: 100);

      expect(updated.state, LearningItemState.learning);
      expect(updated.nextReviewDay, 101);
    });

    test('mastered -> mastered on correct, extends to 120 days', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.mastered,
        step: LearningItem.mastered60d,
        nextReviewDay: 100,
        lastAnsweredDay: 40,
      );
      final updated = item.recordAnswer(isCorrect: true, today: 100);

      expect(updated.state, LearningItemState.mastered);
      expect(updated.step, LearningItem.mastered120d);
      expect(updated.nextReviewDay, 220);
    });

    test('mastered -> mastered on correct, stays at 120 days', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.mastered,
        step: LearningItem.mastered120d,
        nextReviewDay: 100,
        lastAnsweredDay: -20,
      );
      final updated = item.recordAnswer(isCorrect: true, today: 100);

      expect(updated.state, LearningItemState.mastered);
      expect(updated.step, LearningItem.mastered120d);
      expect(updated.nextReviewDay, 220);
    });

    test(
      'mastered -> consolidating recovery on incorrect, next review +1 day',
      () {
        const item = LearningItem(
          notionId: 'notion_a',
          state: LearningItemState.mastered,
          step: LearningItem.mastered60d,
          nextReviewDay: 100,
          lastAnsweredDay: 40,
        );
        final updated = item.recordAnswer(isCorrect: false, today: 100);

        expect(updated.state, LearningItemState.consolidating);
        expect(updated.step, LearningItem.recoveryStep);
        expect(updated.nextReviewDay, 101);
      },
    );

    test(
      'consolidating recovery -> consolidating step 0 on correct, next review +3 days',
      () {
        const item = LearningItem(
          notionId: 'notion_a',
          state: LearningItemState.consolidating,
          step: LearningItem.recoveryStep,
          nextReviewDay: 100,
          lastAnsweredDay: 99,
        );
        final updated = item.recordAnswer(isCorrect: true, today: 100);

        expect(updated.state, LearningItemState.consolidating);
        expect(updated.step, LearningItem.consolidating3d);
        expect(updated.nextReviewDay, 103);
      },
    );

    test('recovery -> learning on incorrect, next review +1 day', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.consolidating,
        step: LearningItem.recoveryStep,
        nextReviewDay: 100,
        lastAnsweredDay: 99,
      );
      final updated = item.recordAnswer(isCorrect: false, today: 100);

      expect(updated.state, LearningItemState.learning);
      expect(updated.nextReviewDay, 101);
    });
  });

  group('LearningItem timing edge cases', () {
    test('correct before due date does not advance state', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.learning,
        step: -1,
        nextReviewDay: 105,
        lastAnsweredDay: 100,
      );
      final updated = item.recordAnswer(isCorrect: true, today: 102);

      expect(updated.state, LearningItemState.learning);
      expect(updated.nextReviewDay, 105);
    });

    test('wrong before due date still regresses', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.consolidating,
        step: LearningItem.consolidating7d,
        nextReviewDay: 107,
        lastAnsweredDay: 100,
      );
      final updated = item.recordAnswer(isCorrect: false, today: 102);

      expect(updated.state, LearningItemState.learning);
      expect(updated.nextReviewDay, 103);
    });

    test('correct late answer advances only one step from today', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.learning,
        step: -1,
        nextReviewDay: 100,
        lastAnsweredDay: 99,
      );
      final updated = item.recordAnswer(isCorrect: true, today: 110);

      expect(updated.state, LearningItemState.consolidating);
      expect(updated.step, LearningItem.consolidating3d);
      expect(updated.nextReviewDay, 113);
    });

    test('wrong late answer applies normal regression from today', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.consolidating,
        step: LearningItem.consolidating21d,
        nextReviewDay: 100,
        lastAnsweredDay: 79,
      );
      final updated = item.recordAnswer(isCorrect: false, today: 150);

      expect(updated.state, LearningItemState.learning);
      expect(updated.nextReviewDay, 151);
    });

    test('very long absence does not auto-regress items', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.mastered,
        step: LearningItem.mastered120d,
        nextReviewDay: 200,
        lastAnsweredDay: 80,
      );
      expect(item.state, LearningItemState.mastered);
      expect(item.nextReviewDay, 200);
    });

    test(
      'multiple correct answers same day cannot reach mastered artificially',
      () {
        var item = const LearningItem.newItem(notionId: 'notion_a');
        item = item.recordAnswer(isCorrect: true, today: 100);
        expect(item.state, LearningItemState.learning);

        item = item.recordAnswer(isCorrect: true, today: 100);
        expect(item.state, LearningItemState.learning);

        item = item.recordAnswer(isCorrect: true, today: 100);
        expect(item.state, LearningItemState.learning);
      },
    );

    test('isOverdue returns true when past review date', () {
      const item = LearningItem(
        notionId: 'notion_a',
        state: LearningItemState.learning,
        step: -1,
        nextReviewDay: 100,
        lastAnsweredDay: 99,
      );
      expect(item.isOverdue(110), isTrue);
      expect(item.isOverdue(100), isTrue);
      expect(item.isOverdue(99), isFalse);
    });

    test('newItem is never overdue', () {
      const item = LearningItem.newItem(notionId: 'notion_a');
      expect(item.isOverdue(200), isFalse);
    });

    test('isEligibleForReview returns true for newItem always', () {
      const item = LearningItem.newItem(notionId: 'notion_a');
      expect(item.isEligibleForReview(200), isTrue);
    });
  });

  group('LearningItem serialization', () {
    test('round-trips through JSON', () {
      const item = LearningItem.newItem(notionId: 'notion_a');
      final json = item.toJson();
      final restored = LearningItem.fromJson(json);

      expect(restored.notionId, 'notion_a');
      expect(restored.state, LearningItemState.newItem);
    });

    test('round-trips mastered item', () {
      const item = LearningItem(
        notionId: 'notion_b',
        state: LearningItemState.mastered,
        step: LearningItem.mastered120d,
        nextReviewDay: 300,
        lastAnsweredDay: 180,
      );
      final json = item.toJson();
      final restored = LearningItem.fromJson(json);

      expect(restored.notionId, 'notion_b');
      expect(restored.state, LearningItemState.mastered);
      expect(restored.step, LearningItem.mastered120d);
      expect(restored.nextReviewDay, 300);
      expect(restored.lastAnsweredDay, 180);
    });
  });

  group('GameProgress', () {
    test('returns newItem for unknown notion', () {
      const progress = GameProgress();
      final item = progress.progressFor('unknown');
      expect(item.state, LearningItemState.newItem);
    });

    test('counts overdue items', () {
      var progress = const GameProgress();
      progress = progress.recordAnswer(
        notionId: 'a',
        isCorrect: true,
        today: 100,
      );
      progress = progress.recordAnswer(
        notionId: 'b',
        isCorrect: true,
        today: 100,
      );

      expect(progress.countOverdue(105), 2);
      expect(progress.countOverdue(99), 0);
    });

    test('counts eligible items', () {
      var progress = const GameProgress();
      progress = progress.recordAnswer(
        notionId: 'a',
        isCorrect: true,
        today: 100,
      );

      expect(progress.countEligible(105), 1);
      expect(progress.countEligible(99), 0);
    });

    test('counts only mastered items', () {
      final progress = GameProgress(
        items: const {
          'mastered_a': LearningItem(
            notionId: 'mastered_a',
            state: LearningItemState.mastered,
            step: LearningItem.mastered60d,
            nextReviewDay: 200,
            lastAnsweredDay: 140,
          ),
          'learning_b': LearningItem(
            notionId: 'learning_b',
            state: LearningItemState.learning,
            step: LearningItem.initialStep,
            nextReviewDay: 101,
            lastAnsweredDay: 100,
          ),
          'consolidating_c': LearningItem(
            notionId: 'consolidating_c',
            state: LearningItemState.consolidating,
            step: LearningItem.consolidating3d,
            nextReviewDay: 103,
            lastAnsweredDay: 100,
          ),
        },
      );

      expect(progress.countMastered(), 1);
    });

    test('countMastered returns 0 for empty progress', () {
      expect(const GameProgress().countMastered(), 0);
    });

    test('counts started items across non-new states', () {
      final progress = GameProgress(
        items: const {
          'mastered_a': LearningItem(
            notionId: 'mastered_a',
            state: LearningItemState.mastered,
            step: LearningItem.mastered60d,
            nextReviewDay: 200,
            lastAnsweredDay: 140,
          ),
          'learning_b': LearningItem(
            notionId: 'learning_b',
            state: LearningItemState.learning,
            step: LearningItem.initialStep,
            nextReviewDay: 101,
            lastAnsweredDay: 100,
          ),
          'consolidating_c': LearningItem(
            notionId: 'consolidating_c',
            state: LearningItemState.consolidating,
            step: LearningItem.consolidating3d,
            nextReviewDay: 103,
            lastAnsweredDay: 100,
          ),
        },
      );

      expect(progress.countStarted(), 3);
    });

    test('countStarted returns 0 for empty progress', () {
      expect(const GameProgress().countStarted(), 0);
    });
  });

  group('UserProgress', () {
    test('serializes and deserializes correctly', () {
      var progress = const UserProgress();
      progress = progress.recordAnswer(
        gameId: 'vocabulary',
        notionId: 'v_curios',
        isCorrect: true,
        today: 100,
      );

      final json = progress.toJson();
      final restored = UserProgress.fromJson(json);

      final item = restored.forGame('vocabulary').progressFor('v_curios');
      expect(item.state, LearningItemState.learning);
      expect(item.nextReviewDay, 101);
    });

    test('returns empty progress for unknown game', () {
      const progress = UserProgress();
      final gameProgress = progress.forGame('nonexistent');
      expect(gameProgress.items, isEmpty);
    });
  });

  group('RoundSelector single notion', () {
    List<_TestEx> buildExercises() {
      return [
        const _TestEx('late_word', 'n_late'),
        const _TestEx('due_word', 'n_due'),
        const _TestEx('new_word', 'n_new'),
        const _TestEx('future_word', 'n_future'),
      ];
    }

    test('all items returned match count', () {
      var progress = const GameProgress();
      progress = progress.recordAnswer(
        notionId: 'n_late',
        isCorrect: true,
        today: 90,
      );

      final result = RoundSelector.select(
        exercises: buildExercises(),
        count: 4,
        progress: progress,
        notionIdOf: (ex) => ex.id,
        today: 105,
        random: Random(42),
      );

      expect(result.length, 4);
    });

    test('avoids same notion multiple times in a round', () {
      final progress = const GameProgress();
      final exercises = [
        const _TestEx('variant_a', 'notion_x'),
        const _TestEx('variant_b', 'notion_x'),
        const _TestEx('other', 'notion_y'),
      ];

      final result = RoundSelector.select(
        exercises: exercises,
        count: 2,
        progress: progress,
        notionIdOf: (ex) => ex.id,
      );

      final notionIds = result.map((e) => e.id).toSet();
      expect(notionIds.length, 2);
    });

    test('includes ineligible when not enough eligible exercises', () {
      var progress = const GameProgress();
      progress = progress.recordAnswer(
        notionId: 'future',
        isCorrect: true,
        today: 100,
      );

      final exercises = [
        const _TestEx('future', 'future'),
        const _TestEx('also_future', 'also_future'),
      ];

      final result = RoundSelector.select(
        exercises: exercises,
        count: 2,
        progress: progress,
        notionIdOf: (ex) => ex.id,
      );

      expect(result.length, 2);
    });

    test('does not flood overdue items after long absence', () {
      var progress = const GameProgress();
      for (var i = 0; i < 20; i++) {
        progress = progress.recordAnswer(
          notionId: 'notion_$i',
          isCorrect: true,
          today: 50 + i,
        );
      }

      final exercises =
          List.generate(20, (i) => _TestEx('notion_$i', 'notion_$i'));

      final result = RoundSelector.select(
        exercises: exercises,
        count: 10,
        progress: progress,
        notionIdOf: (ex) => ex.id,
        today: 105,
      );

      expect(result.length, 10);
    });

    test('orders items by difficulty ascending, stable by notion id', () {
      final progress = const GameProgress();
      final exercises = [
        const _TestEx('b', 'notion_2', difficulty: 2),
        const _TestEx('a1', 'notion_1', difficulty: 1),
        const _TestEx('c', 'notion_3', difficulty: 2),
        const _TestEx('a0', 'notion_0', difficulty: 1),
      ];

      final result = RoundSelector.select(
        exercises: exercises,
        count: 4,
        progress: progress,
        notionIdOf: (e) => e.id,
        difficultyOf: (e) => e.difficulty,
        today: 100,
      );

      expect(result.map((e) => e.label).toList(), ['a0', 'a1', 'b', 'c']);
    });

    test('serves overdue before new before ineligible', () {
      var progress = const GameProgress();
      progress = progress.recordAnswer(
        notionId: 'n_overdue',
        isCorrect: true,
        today: 90,
      );
      progress = progress.recordAnswer(
        notionId: 'n_future',
        isCorrect: true,
        today: 100,
      );

      final exercises = [
        const _TestEx('future', 'n_future'),
        const _TestEx('new', 'n_new'),
        const _TestEx('overdue', 'n_overdue'),
      ];

      final result = RoundSelector.select(
        exercises: exercises,
        count: 3,
        progress: progress,
        notionIdOf: (e) => e.id,
        difficultyOf: (e) => e.difficulty,
        today: 100,
      );

      expect(
        result.map((e) => e.label).toList(),
        ['overdue', 'new', 'future'],
      );
    });

    test('two rounds deterministically consume new items easy-to-hard', () {
      const progress = GameProgress();
      final exercises = [
        const _TestEx('n4', 'n4', difficulty: 4),
        const _TestEx('n1', 'n1', difficulty: 1),
        const _TestEx('n3', 'n3', difficulty: 3),
        const _TestEx('n2', 'n2', difficulty: 2),
      ];

      final round1 = RoundSelector.select(
        exercises: exercises,
        count: 2,
        progress: progress,
        notionIdOf: (e) => e.id,
        difficultyOf: (e) => e.difficulty,
        today: 100,
      );
      expect(round1.map((e) => e.label).toList(), ['n1', 'n2']);

      var updated = progress;
      for (final e in round1) {
        updated = updated.recordAnswer(
          notionId: e.id,
          isCorrect: true,
          today: 100,
        );
      }

      final round2 = RoundSelector.select(
        exercises: exercises,
        count: 2,
        progress: updated,
        notionIdOf: (e) => e.id,
        difficultyOf: (e) => e.difficulty,
        today: 100,
      );
      expect(round2.map((e) => e.label).toList(), ['n3', 'n4']);
    });

    test('reserves a slot for a new item even with many overdue', () {
      var progress = const GameProgress();
      for (var i = 0; i < 10; i++) {
        progress = progress.recordAnswer(
          notionId: 'due_$i',
          isCorrect: true,
          today: 90,
        );
      }

      final exercises = [
        ...List.generate(10, (i) => _TestEx('due_$i', 'due_$i')),
        const _TestEx('new_easy', 'new_easy', difficulty: 1),
      ];

      final result = RoundSelector.select(
        exercises: exercises,
        count: 10,
        progress: progress,
        notionIdOf: (e) => e.id,
        difficultyOf: (e) => e.difficulty,
        today: 100,
      );

      expect(result, hasLength(10));
      expect(result.any((e) => e.label == 'new_easy'), isTrue);
      expect(result.where((e) => e.label != 'new_easy'), hasLength(9));
    });
  });

  group('RoundSelector multi notion', () {
    test('selects exercises based on highest-priority notion', () {
      var progress = const GameProgress();
      progress = progress.recordAnswer(
        notionId: 'n_overdue',
        isCorrect: true,
        today: 90,
      );
      progress = progress.recordAnswer(
        notionId: 'n_due',
        isCorrect: true,
        today: 99,
      );

      final exercises = [
        const _MultiNotionEx('text_a', ['n_overdue', 'n_new_a']),
        const _MultiNotionEx('text_b', ['n_due', 'n_fresh']),
        const _MultiNotionEx('text_c', ['n_new_b']),
        const _MultiNotionEx('text_d', ['n_future']),
      ];

      final result = RoundSelector.selectMultiNotion(
        exercises: exercises,
        count: 4,
        progress: progress,
        notionIdsOf: (ex) => ex.notionIds,
        today: 105,
        random: Random(42),
      );

      expect(result.length, 4);
      final overdueIds =
          result.takeWhile((e) => e.notionIds.contains('n_overdue') || e.notionIds.contains('n_due'));
      expect(overdueIds.isNotEmpty, isTrue);
    });

    test('avoids overlapping notions between selected exercises', () {
      var progress = const GameProgress();
      final exercises = [
        const _MultiNotionEx('text_a', ['notion_x', 'notion_a']),
        const _MultiNotionEx('text_b', ['notion_x', 'notion_b']),
      ];

      final result = RoundSelector.selectMultiNotion(
        exercises: exercises,
        count: 2,
        progress: progress,
        notionIdsOf: (ex) => ex.notionIds,
        today: 100,
      );

      expect(result.length, 1);
    });

    test('orders by text difficulty ascending', () {
      const progress = GameProgress();
      final exercises = [
        const _MultiNotionEx('hard', ['n_h_a', 'n_h_b'], difficulty: 5),
        const _MultiNotionEx('easy', ['n_e_a'], difficulty: 1),
        const _MultiNotionEx('mid', ['n_m_a'], difficulty: 3),
      ];

      final result = RoundSelector.selectMultiNotion(
        exercises: exercises,
        count: 3,
        progress: progress,
        notionIdsOf: (e) => e.notionIds,
        difficultyOf: (e) => e.difficulty,
        today: 100,
      );

      expect(result.map((e) => e.label).toList(), ['easy', 'mid', 'hard']);
    });

    test('orders by difficulty while avoiding overlapping notions', () {
      const progress = GameProgress();
      final exercises = [
        const _MultiNotionEx('easy', ['n_shared', 'n_easy'], difficulty: 1),
        const _MultiNotionEx('hard_overlap', ['n_shared', 'n_hard'], difficulty: 5),
        const _MultiNotionEx('mid', ['n_mid'], difficulty: 3),
      ];

      final result = RoundSelector.selectMultiNotion(
        exercises: exercises,
        count: 3,
        progress: progress,
        notionIdsOf: (e) => e.notionIds,
        difficultyOf: (e) => e.difficulty,
        today: 100,
      );

      expect(result.map((e) => e.label).toList(), ['easy', 'mid']);
    });
  });
}

final class _TestEx {
  final String label;
  final String id;
  final int difficulty;

  const _TestEx(this.label, this.id, {this.difficulty = 0});

  @override
  bool operator ==(Object other) =>
      other is _TestEx && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

final class _MultiNotionEx {
  final String label;
  final List<String> notionIds;
  final int difficulty;

  const _MultiNotionEx(this.label, this.notionIds, {this.difficulty = 0});

  @override
  bool operator ==(Object other) =>
      other is _MultiNotionEx &&
      other.label == label &&
      _listEquals(other.notionIds, notionIds);

  @override
  int get hashCode => Object.hashAll([label, ...notionIds]);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
