import 'package:flutter/material.dart';

import '../animations.dart';
import '../colors.dart';
import '../radius.dart';
import '../shadows.dart';
import '../spacing.dart';
import '../typography.dart';

class LexioGameCard extends StatelessWidget {
  const LexioGameCard({
    super.key,
    required this.title,
    this.semanticLabel,
    required this.accentColor,
    required this.mutedColor,
    required this.discovered,
    required this.total,
    required this.onTap,
  });

  final String title;
  final String? semanticLabel;
  final Color accentColor;
  final Color mutedColor;
  final int discovered;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (discovered / total).clamp(0.0, 1.0);

    return Semantics(
      container: true,
      button: true,
      label:
          '${semanticLabel ?? 'Joc $title'}, progres $discovered din $total',
      onTap: onTap,
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LexioRadius.xl),
          boxShadow: LexioShadows.cardCombined,
        ),
        child: Material(
          color: LexioColors.surface,
          borderRadius: BorderRadius.circular(LexioRadius.xl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: fraction),
                      duration: LexioDurations.normal,
                      curve: LexioCurves.easeOut,
                      builder: (context, value, child) {
                        return FractionallySizedBox(
                          key: const ValueKey('game_card_fill'),
                          widthFactor: value,
                          heightFactor: 1,
                          child: ColoredBox(color: mutedColor),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(LexioSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$discovered/$total',
                        style: LexioTextStyles.labelSmall.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: LexioSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: LexioTextStyles.displayMedium.copyWith(
                                color: LexioColors.textPrimary,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'NoticiaText',
                              ),
                            ),
                          ),
                          const SizedBox(width: LexioSpacing.md),
                          Icon(
                            Icons.arrow_forward,
                            color: accentColor,
                            size: LexioSpacing.xl,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
