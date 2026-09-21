import 'package:flutter/material.dart';
import '../colors.dart';
import '../radius.dart';
import '../shadows.dart';
import '../sizes.dart';
import '../spacing.dart';
import '../typography.dart';

class LexioFeedback extends StatelessWidget {
  const LexioFeedback({
    super.key,
    required this.message,
    this.description,
    this.type = LexioFeedbackType.info,
    this.action,
    this.actionLabel,
  });

  final String message;
  final String? description;
  final LexioFeedbackType type;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForType(type);

    return Container(
      padding: const EdgeInsets.all(LexioSpacing.lg),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(LexioRadius.lg),
        border: Border.all(color: colors.border),
        boxShadow: LexioShadows.cardCombined,
      ),
      child: Row(
        crossAxisAlignment: description != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(
            _iconForType(type),
            color: colors.icon,
            size: LexioSizes.iconFeedback,
          ),
          const SizedBox(width: LexioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: LexioTextStyles.labelMedium.copyWith(
                    color: colors.text,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: LexioSpacing.xs),
                  Text(
                    description!,
                    style: LexioTextStyles.bodySmall.copyWith(
                      color: colors.description,
                    ),
                  ),
                ],
                if (action != null && actionLabel != null) ...[
                  const SizedBox(height: LexioSpacing.sm),
                  TextButton(
                    onPressed: action,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: colors.text,
                    ),
                    child: Text(
                      actionLabel!,
                      style: LexioTextStyles.labelMedium.copyWith(
                        color: colors.text,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(LexioFeedbackType type) {
    return switch (type) {
      LexioFeedbackType.success => Icons.check_circle_outline,
      LexioFeedbackType.error => Icons.error_outline,
      LexioFeedbackType.warning => Icons.warning_amber_rounded,
      LexioFeedbackType.info => Icons.info_outline,
    };
  }

  static _FeedbackColors _colorsForType(LexioFeedbackType type) {
    return switch (type) {
      LexioFeedbackType.success => _FeedbackColors(
        background: LexioColors.successBackground,
        border: LexioColors.success.withValues(alpha: 0.3),
        icon: LexioColors.success,
        text: LexioColors.success,
        description: LexioColors.textSecondary,
      ),
      LexioFeedbackType.error => _FeedbackColors(
        background: LexioColors.errorBackground,
        border: LexioColors.error.withValues(alpha: 0.3),
        icon: LexioColors.error,
        text: LexioColors.error,
        description: LexioColors.textSecondary,
      ),
      LexioFeedbackType.warning => _FeedbackColors(
        background: LexioColors.warningBackground,
        border: LexioColors.warning.withValues(alpha: 0.3),
        icon: LexioColors.warning,
        text: LexioColors.warning,
        description: LexioColors.textSecondary,
      ),
      LexioFeedbackType.info => _FeedbackColors(
        background: LexioColors.infoBackground,
        border: LexioColors.info.withValues(alpha: 0.3),
        icon: LexioColors.info,
        text: LexioColors.info,
        description: LexioColors.textSecondary,
      ),
    };
  }
}

enum LexioFeedbackType { success, error, warning, info }

class _FeedbackColors {
  final Color background;
  final Color border;
  final Color icon;
  final Color text;
  final Color description;

  const _FeedbackColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
    required this.description,
  });
}
