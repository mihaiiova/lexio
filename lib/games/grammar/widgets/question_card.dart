import 'package:flutter/material.dart';
import '../../../design/theme.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.sentence,
  });

  final String sentence;

  @override
  Widget build(BuildContext context) {
    return Text(
      sentence,
      style: LexioTheme.sentenceTextStyle(),
    );
  }
}
