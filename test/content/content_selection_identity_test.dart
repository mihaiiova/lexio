import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/progress/learning_item.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/user_progress.dart';

final class _Exercise {
  const _Exercise(this.id, this.notionId);

  final String id;
  final String notionId;
}

final class _Text {
  const _Text(this.id, this.notionIds);

  final String id;
  final List<String> notionIds;
}

void main() {
  test('selection keeps identity stable across revisions and removals', () {
    const today = 100;
    final progress = GameProgress(
      items: {
        'due': LearningItem(
          notionId: 'due',
          state: LearningItemState.learning,
          step: LearningItem.initialStep,
          nextReviewDay: today,
          lastAnsweredDay: today - 1,
        ),
        'removed': LearningItem(
          notionId: 'removed',
          state: LearningItemState.learning,
          step: LearningItem.initialStep,
          nextReviewDay: today,
          lastAnsweredDay: today - 1,
        ),
        'mastered': LearningItem(
          notionId: 'mastered',
          state: LearningItemState.mastered,
          step: LearningItem.mastered60d,
          nextReviewDay: today + 60,
          lastAnsweredDay: today - 1,
        ),
      },
    );
    const exercises = [
      _Exercise('revised_due', 'due'),
      _Exercise('new_concept', 'new'),
      _Exercise('mastered_copy', 'mastered'),
      _Exercise('duplicate_due', 'due'),
    ];

    final selected = RoundSelector.select(
      exercises: exercises,
      count: 3,
      progress: progress,
      notionIdOf: (exercise) => exercise.notionId,
      today: today,
    );

    expect(selected.map((exercise) => exercise.id), contains('revised_due'));
    expect(
      selected.map((exercise) => exercise.notionId),
      isNot(contains('removed')),
    );
    expect(
      selected.map((exercise) => exercise.notionId).toSet(),
      hasLength(selected.length),
    );
  });

  test('multi-notion selection excludes overlapping texts', () {
    const today = 100;
    final selected = RoundSelector.selectMultiNotion(
      exercises: const [
        _Text('first', ['a', 'b']),
        _Text('overlap', ['b', 'c']),
        _Text('independent', ['d']),
      ],
      count: 3,
      progress: const GameProgress(),
      notionIdsOf: (text) => text.notionIds,
      today: today,
    );

    final notions = selected.expand((text) => text.notionIds).toList();
    expect(notions.toSet(), hasLength(notions.length));
  });
}
