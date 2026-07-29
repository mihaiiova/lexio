import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../../../design/theme.dart';
import '../vocabulary_content.dart';

class VocabularySentence extends StatelessWidget {
  const VocabularySentence({super.key, required this.exercise});

  final VocabularyExercise exercise;

  @override
  Widget build(BuildContext context) {
    final sentence = exercise.example;
    final highlightedMatch = _findHighlightedWord(sentence, exercise.word);
    final sentenceStyle = LexioTheme.sentenceTextStyle(
      LexioColors.textPrimary,
    ).copyWith(fontWeight: FontWeight.w400);

    if (highlightedMatch == null) {
      return Text(sentence, style: sentenceStyle);
    }

    return RichText(
      text: TextSpan(
        style: sentenceStyle,
        children: [
          TextSpan(text: sentence.substring(0, highlightedMatch.start)),
          TextSpan(
            text: sentence.substring(
              highlightedMatch.start,
              highlightedMatch.end,
            ),
            style: const TextStyle(
              backgroundColor: LexioColors.blueMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: sentence.substring(highlightedMatch.end)),
        ],
      ),
    );
  }

  RegExpMatch? _findHighlightedWord(String sentence, String word) {
    final baseWord = word
        .toLowerCase()
        .replaceFirst('a se ', '')
        .replaceFirst('a ', '');
    final words = RegExp(
      r'[A-Za-zĂÂÎȘȚăâîșț]+',
    ).allMatches(sentence).toList(growable: false);

    for (var length = baseWord.length; length >= 3; length--) {
      final prefix = baseWord.substring(0, length);
      for (final match in words) {
        if (match.group(0)!.toLowerCase().startsWith(prefix)) {
          return match;
        }
      }
    }

    return null;
  }
}
