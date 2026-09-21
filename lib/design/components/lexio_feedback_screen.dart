import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import 'lexio_feedback.dart';

class LexioFeedbackScreen extends StatelessWidget {
  const LexioFeedbackScreen({
    super.key,
    required this.message,
    this.description,
    this.type = LexioFeedbackType.info,
    this.action,
    this.actionLabel,
    this.backgroundColor = LexioColors.surface,
    this.appBar,
  });

  final String message;
  final String? description;
  final LexioFeedbackType type;
  final VoidCallback? action;
  final String? actionLabel;
  final Color backgroundColor;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LexioSpacing.screenHorizontal,
            ),
            child: LexioFeedback(
              type: type,
              message: message,
              description: description,
              actionLabel: actionLabel,
              action: action,
            ),
          ),
        ),
      ),
    );
  }
}
