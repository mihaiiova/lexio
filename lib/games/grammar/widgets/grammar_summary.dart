import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../../../design/components/lexio_game_summary.dart';
import '../grammar_game.dart';

class GrammarSummary extends StatelessWidget {
  const GrammarSummary({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onBack,
  });

  final GrammarGameState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final reviewItems = <LexioReviewItem>[];
    for (var index = 0; index < state.exercises.length; index++) {
      if (state.results[index] != false) continue;

      final exercise = state.exercises[index];
      reviewItems.add(
        LexioReviewItem(
          wrongAnswer: exercise.isCorrect
              ? 'Ai ales „Greșit”: ${exercise.sentence}'
              : exercise.sentence,
          correctAnswer: exercise.isCorrect
              ? 'Propoziția este corectă.'
              : exercise.correctSentence ?? 'Propoziția conține o greșeală.',
          explanation: exercise.explanation,
        ),
      );
    }

    return LexioGameSummary(
      gameNumber: '01',
      gameTitle: 'Corect sau greșit?',
      accentColor: LexioColors.blue,
      correctCount: state.correctCount,
      totalCount: state.exercises.length,
      reviewItems: reviewItems,
      onPlayAgain: onPlayAgain,
      onBack: onBack,
    );
  }
}
