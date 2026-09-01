import 'package:flutter/material.dart';

import '../colors.dart';
import '../radius.dart';
import '../sizes.dart';
import '../spacing.dart';
import '../typography.dart';

class LexioDiscoveryProgress extends StatelessWidget {
  const LexioDiscoveryProgress({
    super.key,
    required this.discovered,
    required this.total,
    this.accentColor = LexioColors.primary,
  });

  final int discovered;
  final int total;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (discovered / total).clamp(0.0, 1.0);

    return Semantics(
      container: true,
      label: '$discovered din $total',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(LexioRadius.full),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: LexioSizes.progressBarActive,
                backgroundColor: LexioColors.shimmer,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ),
          const SizedBox(width: LexioSpacing.sm),
          Text(
            '$discovered din $total',
            style: LexioTextStyles.labelSmall.copyWith(
              color: LexioColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
