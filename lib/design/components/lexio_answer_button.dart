import 'package:flutter/material.dart';

import '../animations.dart';
import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';

enum LexioAnswerButtonState { idle, correct, incorrect, disabled }

enum LexioAnswerButtonTone { neutral, positive, negative }

class LexioAnswerButton extends StatelessWidget {
  const LexioAnswerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.state = LexioAnswerButtonState.idle,
    this.tone = LexioAnswerButtonTone.neutral,
  });

  final String label;
  final VoidCallback? onPressed;
  final LexioAnswerButtonState state;
  final LexioAnswerButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final isEnabled =
        onPressed != null && state != LexioAnswerButtonState.disabled;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: AnimatedContainer(
        duration: LexioDurations.instant,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(LexioRadius.lg),
          border: Border.all(color: colors.border, width: LexioSpacing.xxs),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LexioSpacing.lg,
                vertical: LexioSpacing.md,
              ),
              child: Text(
                label,
                style: LexioTextStyles.bodyMedium.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  _AnswerButtonColors get _colors {
    switch (state) {
      case LexioAnswerButtonState.correct:
        return const _AnswerButtonColors(
          background: LexioColors.greenMuted,
          foreground: LexioColors.green,
          border: LexioColors.green,
        );
      case LexioAnswerButtonState.incorrect:
        return const _AnswerButtonColors(
          background: LexioColors.redMuted,
          foreground: LexioColors.red,
          border: LexioColors.red,
        );
      case LexioAnswerButtonState.disabled:
        return const _AnswerButtonColors(
          background: LexioColors.surface,
          foreground: LexioColors.textTertiary,
          border: LexioColors.divider,
        );
      case LexioAnswerButtonState.idle:
        return switch (tone) {
          LexioAnswerButtonTone.neutral => const _AnswerButtonColors(
            background: LexioColors.surface,
            foreground: LexioColors.textPrimary,
            border: LexioColors.divider,
          ),
          LexioAnswerButtonTone.positive => const _AnswerButtonColors(
            background: LexioColors.greenMuted,
            foreground: LexioColors.green,
            border: LexioColors.green,
          ),
          LexioAnswerButtonTone.negative => const _AnswerButtonColors(
            background: LexioColors.redMuted,
            foreground: LexioColors.red,
            border: LexioColors.red,
          ),
        };
    }
  }
}

final class _AnswerButtonColors {
  const _AnswerButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
