import 'package:flutter/material.dart';

import '../animations.dart';
import '../colors.dart';
import '../radius.dart';
import '../shadows.dart';
import '../spacing.dart';
import '../typography.dart';

/// A game entry rendered as a card whose background doubles as a progress bar.
///
/// The card has a white base; a full-height fill in [mutedColor] grows
/// left-to-right to the [progress] fraction, covering the whole card. The
/// number and chevron use [accentColor] while the title stays dark.
class LexioGameCard extends StatelessWidget {
  const LexioGameCard({
    super.key,
    required this.number,
    required this.title,
    required this.accentColor,
    required this.mutedColor,
    required this.progress,
    required this.onTap,
  });

  final String number;
  final String title;
  final Color accentColor;
  final Color mutedColor;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = progress.clamp(0.0, 1.0);
    final percent = (fraction * 100).round();

    return Semantics(
      container: true,
      button: true,
      label: 'Joc $number: $title, progres $percent%',
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
                        number,
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
                              style: LexioTextStyles.displayLarge.copyWith(
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
