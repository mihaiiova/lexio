import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../../../design/components/lexio_button.dart';
import '../../../design/components/lexio_card.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../spot_game.dart';

class SpotSummary extends StatelessWidget {
  final SpotGameState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  const SpotSummary({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isTimed = state.mode == SpotGameMode.timed;
    final headerText = isTimed ? 'Timpul a expirat!' : 'Bravo!';
    final headerEmoji = isTimed ? '⏰' : '🎉';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: LexioSpacing.screenHorizontal,
        vertical: LexioSpacing.xl,
      ),
      child: Column(
        children: [
          const SizedBox(height: LexioSpacing.xxl),
          Text(
            headerEmoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: LexioSpacing.md),
          Text(
            headerText,
            style: LexioTextStyles.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LexioSpacing.sm),
          Text(
            'Ai găsit greșelile din texte.',
            style: LexioTextStyles.bodySmall.copyWith(
              color: LexioColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LexioSpacing.xxl),
          _buildStatsGrid(),
          const SizedBox(height: LexioSpacing.xxl),
          LexioButton(
            label: 'Joacă din nou',
            variant: LexioButtonVariant.primary,
            isExpanded: true,
            onPressed: onPlayAgain,
          ),
          const SizedBox(height: LexioSpacing.md),
          LexioButton(
            label: 'Înapoi',
            variant: LexioButtonVariant.ghost,
            isExpanded: true,
            onPressed: onBack,
          ),
          const SizedBox(height: LexioSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final elapsed = state.elapsed;
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    final timeStr = '${minutes}m ${seconds}s';

    final stats = [
      _StatItem(
        label: 'Texte completate',
        value: '${state.textsCompleted}',
      ),
      _StatItem(
        label: 'Greșeli găsite',
        value: '${state.totalCorrectTaps}',
      ),
      _StatItem(
        label: 'Precizie',
        value: '${(state.accuracy * 100).round()}%',
      ),
      _StatItem(
        label: 'Timp',
        value: timeStr,
      ),
      _StatItem(
        label: 'Scor',
        value: '${state.score}',
        isAccent: true,
      ),
    ];

    return Wrap(
      spacing: LexioSpacing.md,
      runSpacing: LexioSpacing.md,
      children: stats.map((s) => _buildStatCard(s)).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return SizedBox(
      width: _cardWidth(),
      child: LexioCard(
        padding: const EdgeInsets.all(LexioSpacing.lg),
        child: Column(
          children: [
            Text(
              item.value,
              style: (item.isAccent
                      ? LexioTextStyles.headingMedium
                      : LexioTextStyles.headingSmall)
                  .copyWith(
                color: item.isAccent
                    ? LexioColors.accent
                    : LexioColors.textPrimary,
              ),
            ),
            const SizedBox(height: LexioSpacing.xs),
            Text(
              item.label,
              style: LexioTextStyles.bodySmall.copyWith(
                color: LexioColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  double _cardWidth() {
    final screenWidth = 375.0;
    final padding = LexioSpacing.screenHorizontal * 2;
    final gap = LexioSpacing.md;
    return (screenWidth - padding - gap) / 2;
  }
}

class _StatItem {
  final String label;
  final String value;
  final bool isAccent;

  const _StatItem({
    required this.label,
    required this.value,
    this.isAccent = false,
  });
}
