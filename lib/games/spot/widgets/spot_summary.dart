import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../../../design/components/lexio_game_summary.dart';
import '../spot_game.dart';

class SpotSummary extends StatelessWidget {
  const SpotSummary({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onBack,
  });

  final SpotGameState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final reviewItems = <LexioReviewItem>[];
    var totalMistakes = 0;

    for (var textIndex = 0; textIndex < state.texts.length; textIndex++) {
      final text = state.texts[textIndex];
      final foundMistakes = state.foundMistakeIndices[textIndex];
      totalMistakes += text.mistakes.length;

      for (
        var mistakeIndex = 0;
        mistakeIndex < text.mistakes.length;
        mistakeIndex++
      ) {
        if (foundMistakes.contains(mistakeIndex)) continue;

        final mistake = text.mistakes[mistakeIndex];
        reviewItems.add(
          LexioReviewItem(
            wrongAnswer: mistake.token,
            correctAnswer: mistake.replacement,
            explanation: mistake.explanation,
          ),
        );
      }

      for (final wordIndex in state.incorrectTapWordIndices[textIndex]) {
        final selectedWord = text.words[wordIndex];
        reviewItems.add(
          LexioReviewItem(
            wrongAnswer: 'Ai selectat „$selectedWord”.',
            correctAnswer: 'Cuvântul este corect în acest context.',
            explanation: 'Selecția nu corespunde unei greșeli din text.',
          ),
        );
      }
    }

    return LexioGameSummary(
      accentColor: LexioColors.amber,
      correctCount: state.totalCorrectTaps,
      totalCount: totalMistakes,
      reviewItems: reviewItems,
      onPlayAgain: onPlayAgain,
      onBack: onBack,
    );
  }
}
