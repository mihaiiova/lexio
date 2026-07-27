import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../design/theme.dart';
import '../../../design/animations.dart';
import '../grammar_content.dart';

class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.exercise,
  });

  final GrammarExercise exercise;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: LexioDurations.reveal,
      curve: LexioCurves.smooth,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LexioSpacing.screenHorizontal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCorrection(),
            const SizedBox(height: LexioSpacing.xxl),
            Text(
              exercise.explanation,
              style: LexioTextStyles.bodyMedium.copyWith(
                color: LexioColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrection() {
    final sentence = exercise.sentence;
    final correct = exercise.correctSentence;

    if (correct == null) {
      return Text(
        sentence,
        style: LexioTextStyles.headingMedium.copyWith(
          color: LexioColors.error,
          height: 1.5,
        ),
      );
    }

    return _buildDiff(sentence, correct);
  }

  Widget _buildDiff(String wrongSentence, String correctSentence) {
    final wrongWords = wrongSentence.split(' ');
    final correctWords = correctSentence.split(' ');

    // Find common prefix
    var prefixEnd = 0;
    while (prefixEnd < wrongWords.length &&
        prefixEnd < correctWords.length &&
        wrongWords[prefixEnd] == correctWords[prefixEnd]) {
      prefixEnd++;
    }

    // Find common suffix
    var suffixStartWrong = wrongWords.length;
    var suffixStartCorrect = correctWords.length;
    while (suffixStartWrong > prefixEnd &&
        suffixStartCorrect > prefixEnd &&
        wrongWords[suffixStartWrong - 1] ==
            correctWords[suffixStartCorrect - 1]) {
      suffixStartWrong--;
      suffixStartCorrect--;
    }

    final wrongDiff = wrongWords.sublist(prefixEnd, suffixStartWrong);
    final correctDiff = correctWords.sublist(prefixEnd, suffixStartCorrect);

    final prefixText = wrongWords.sublist(0, prefixEnd).join(' ');
    final suffixText = wrongWords.sublist(suffixStartWrong).join(' ');

    final style = LexioTheme.sentenceTextStyle();

    final strikeStyle = TextStyle(
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      color: LexioColors.error,
      decoration: TextDecoration.lineThrough,
      decorationColor: LexioColors.error,
      decorationThickness: 2,
    );

    final correctStyle = TextStyle(
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      color: LexioColors.success,
    );

    final spans = <InlineSpan>[];

    if (prefixText.isNotEmpty) {
      spans.add(TextSpan(text: '$prefixText '));
    }

    if (wrongDiff.isNotEmpty) {
      spans.add(TextSpan(
        text: wrongDiff.join(' '),
        style: strikeStyle,
      ));
    }

    if (correctDiff.isNotEmpty) {
      if (wrongDiff.isNotEmpty) {
        spans.add(const TextSpan(text: ' '));
      }
      spans.add(TextSpan(
        text: correctDiff.join(' '),
        style: correctStyle,
      ));
    }

    if (suffixText.isNotEmpty) {
      final needsSpace =
          wrongDiff.isNotEmpty || correctDiff.isNotEmpty;
      if (needsSpace) {
        spans.add(const TextSpan(text: ' '));
      }
      spans.add(TextSpan(text: suffixText));
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
    );
  }
}
