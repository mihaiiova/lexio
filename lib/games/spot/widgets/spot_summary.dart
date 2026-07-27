import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../../../design/components/lexio_button.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../spot_game.dart';

class SpotSummary extends StatefulWidget {
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
  State<SpotSummary> createState() => _SpotSummaryState();
}

class _SpotSummaryState extends State<SpotSummary>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  double _displayScore = 0;
  String _floatingLabel = '';
  bool _showFloating = false;
  int _phase = 0;
  int _pointsAdded = 0;

  int get _baseScore => widget.state.totalCorrectTaps * 100;
  int get _finalScore => widget.state.score;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _animation.addListener(_onAnimationTick);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_phase == 0) {
          _startPrecisionPhase();
        }
      }
    });

    _controller.forward();
  }

  void _onAnimationTick() {
    final value = _animation.value;

    if (_phase == 0) {
      _displayScore = (_baseScore * value).roundToDouble();

      final newPoints = _displayScore ~/ 100;
      if (newPoints > _pointsAdded && newPoints <= widget.state.totalCorrectTaps) {
        _pointsAdded = newPoints;
        setState(() {
          _floatingLabel = '+100';
          _showFloating = true;
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _phase == 0) {
            setState(() => _showFloating = false);
          }
        });
      }
    } else {
      final baseScore = _baseScore.toDouble();
      final delta = _finalScore - _baseScore;
      _displayScore = (baseScore + delta * value).roundToDouble();
    }
  }

  void _startPrecisionPhase() {
    setState(() {
      _phase = 1;
      _showFloating = false;
      _floatingLabel =
          'Precizie ${(widget.state.accuracy * 100).round()}%';
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _controller.reset();
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimationTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalMistakes = widget.state.texts.fold<int>(
      0,
      (sum, t) => sum + t.mistakes.length,
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: LexioSpacing.screenHorizontal,
            ),
            child: Column(
              children: [
                const SizedBox(height: LexioSpacing.xxxl),
                Text(
                  '⏰ Timpul a expirat!',
                  style: LexioTextStyles.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: LexioSpacing.xxl),
                _buildScoreDisplay(),
                const SizedBox(height: LexioSpacing.lg),
                _buildStatsRow(totalMistakes),
              ],
            ),
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildScoreDisplay() {
    return Column(
      children: [
        Text(
          'Scor',
          style: LexioTextStyles.labelSmall.copyWith(
            color: LexioColors.textTertiary,
          ),
        ),
        const SizedBox(height: LexioSpacing.xs),
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${_displayScore.round()}',
              style: LexioTextStyles.displayLarge.copyWith(
                color: LexioColors.accent,
              ),
            ),
            if (_showFloating || _phase == 1)
              Positioned(
                top: -24,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    if (_phase == 1) {
                      return Opacity(
                        opacity: value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: LexioColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _floatingLabel,
                            style: LexioTextStyles.labelSmall.copyWith(
                              color: LexioColors.secondary,
                            ),
                          ),
                        ),
                      );
                    }
                    return Opacity(
                      opacity: 1 - value,
                      child: Transform.translate(
                        offset: Offset(0, value * -16),
                        child: Text(
                          _floatingLabel,
                          style: LexioTextStyles.labelLarge.copyWith(
                            color: LexioColors.success,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(int totalMistakes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStat('Greșeli găsite', '${widget.state.totalCorrectTaps} / $totalMistakes'),
        const SizedBox(width: LexioSpacing.xxl),
        _buildStat(
          'Precizie',
          '${(widget.state.accuracy * 100).round()}%',
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: LexioTextStyles.headingSmall.copyWith(
            color: LexioColors.textPrimary,
          ),
        ),
        const SizedBox(height: LexioSpacing.xxs),
        Text(
          label,
          style: LexioTextStyles.bodySmall.copyWith(
            color: LexioColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LexioSpacing.screenHorizontal,
        vertical: LexioSpacing.lg,
      ),
      child: Column(
        children: [
          LexioButton(
            label: 'Joacă din nou',
            variant: LexioButtonVariant.primary,
            isExpanded: true,
            onPressed: widget.onPlayAgain,
          ),
          const SizedBox(height: LexioSpacing.md),
          LexioButton(
            label: 'Alege alt joc',
            variant: LexioButtonVariant.ghost,
            isExpanded: true,
            onPressed: widget.onBack,
          ),
          const SizedBox(height: LexioSpacing.lg),
        ],
      ),
    );
  }
}
