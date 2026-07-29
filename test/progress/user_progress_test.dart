import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/progress/user_progress.dart';

void main() {
  group('GameProgress', () {
    test('raises the target difficulty after successful answers', () {
      var progress = const GameProgress();
      for (var index = 0; index < 4; index++) {
        progress = progress.recordAnswer(
          exerciseId: 'exercise_$index',
          difficulty: 1,
          isCorrect: true,
          timestamp: index,
        );
      }

      expect(progress.targetDifficulty, 2);
    });

    test('lowers the target difficulty after incorrect answers', () {
      var progress = const GameProgress(skillScore: 11);
      for (var index = 0; index < 3; index++) {
        progress = progress.recordAnswer(
          exerciseId: 'exercise_$index',
          difficulty: 3,
          isCorrect: false,
          timestamp: index,
        );
      }

      expect(progress.targetDifficulty, 1);
    });

    test('unlocks the fifth difficulty level for sustained mastery', () {
      var progress = const GameProgress();
      for (var index = 0; index < 9; index++) {
        progress = progress.recordAnswer(
          exerciseId: 'exercise_$index',
          difficulty: 3,
          isCorrect: true,
          timestamp: index,
        );
      }

      expect(progress.targetDifficulty, 5);
    });
  });

  group('AdaptiveRound', () {
    test('prefers unseen exercises before repeating answered ones', () {
      final progress = const UserProgress()
          .recordAnswer(
            gameId: 'vocabulary',
            exerciseId: 'seen',
            difficulty: 1,
            isCorrect: true,
            timestamp: 1,
          )
          .forGame('vocabulary');

      final round = AdaptiveRound.select(
        exercises: const [_Exercise('seen', 1), _Exercise('new', 1)],
        count: 2,
        progress: progress,
        idOf: (exercise) => exercise.id,
        difficultyOf: (exercise) => exercise.difficulty,
        random: Random(1),
      );

      expect(round, [const _Exercise('new', 1)]);
    });

    test('revisits weak exercises after all have been seen', () {
      var progress = const GameProgress();
      progress = progress.recordAnswer(
        exerciseId: 'weak',
        difficulty: 1,
        isCorrect: false,
        timestamp: 2,
      );
      progress = progress.recordAnswer(
        exerciseId: 'strong',
        difficulty: 1,
        isCorrect: true,
        timestamp: 1,
      );

      final round = AdaptiveRound.select(
        exercises: const [_Exercise('strong', 1), _Exercise('weak', 1)],
        count: 1,
        progress: progress,
        idOf: (exercise) => exercise.id,
        difficultyOf: (exercise) => exercise.difficulty,
        random: Random(1),
      );

      expect(round, [const _Exercise('weak', 1)]);
    });
  });
}

final class _Exercise {
  final String id;
  final int difficulty;

  const _Exercise(this.id, this.difficulty);

  @override
  bool operator ==(Object other) =>
      other is _Exercise && other.id == id && other.difficulty == difficulty;

  @override
  int get hashCode => Object.hash(id, difficulty);
}
