import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../../../design/theme.dart';
import '../idioms_content.dart';

class IdiomSentence extends StatelessWidget {
  const IdiomSentence({super.key, required this.exercise});

  final IdiomExercise exercise;

  @override
  Widget build(BuildContext context) {
    final sentence = exercise.example;
    final start = sentence.toLowerCase().indexOf(
      exercise.highlightedText.toLowerCase(),
    );
    final sentenceStyle = LexioTheme.sentenceTextStyle(
      LexioColors.textPrimary,
    ).copyWith(fontWeight: FontWeight.w400);

    if (start < 0) {
      return Text(sentence, style: sentenceStyle);
    }

    final end = start + exercise.highlightedText.length;
    return RichText(
      text: TextSpan(
        style: sentenceStyle,
        children: [
          TextSpan(text: sentence.substring(0, start)),
          TextSpan(
            text: sentence.substring(start, end),
            style: const TextStyle(
              backgroundColor: LexioColors.blueMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: sentence.substring(end)),
        ],
      ),
    );
  }
}
