import 'package:flutter/material.dart';

import '../../../design/animations.dart';
import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';

TextStyle _wordStyle(Color color) =>
    LexioTextStyles.spotText.copyWith(color: color);

enum TextTokenState { normal, found, shaking, checking }

class TextToken extends StatelessWidget {
  final String originalText;
  final String correctionText;
  final TextTokenState state;
  final VoidCallback? onTap;

  const TextToken({
    super.key,
    required this.originalText,
    this.correctionText = '',
    this.state = TextTokenState.normal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTappable = state != TextTokenState.found && onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LexioSpacing.hairline,
        vertical: LexioSpacing.tokenVertical,
      ),
      child: MergeSemantics(
        child: Semantics(
          button: isTappable,
          label: originalText,
          child: GestureDetector(
            onTap: isTappable ? onTap : null,
            behavior: HitTestBehavior.opaque,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (state) {
      case TextTokenState.normal:
        return _NormalToken(text: originalText);
      case TextTokenState.found:
        return _FoundToken(original: originalText, correction: correctionText);
      case TextTokenState.shaking:
        return _ShakingToken(text: originalText);
      case TextTokenState.checking:
        return _CheckingToken(
          original: originalText,
          correction: correctionText,
        );
    }
  }
}

class _NormalToken extends StatelessWidget {
  final String text;
  const _NormalToken({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: _wordStyle(LexioColors.textPrimary));
  }
}

class _FoundToken extends StatelessWidget {
  final String original;
  final String correction;
  const _FoundToken({required this.original, required this.correction});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(original, style: _wordStyle(LexioColors.textPrimary)),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: LexioDurations.slow,
          curve: LexioCurves.easeOut,
          builder: (context, value, child) {
            return Opacity(opacity: value.clamp(0.0, 1.0), child: child);
          },
          child: Text(
            original,
            style: _wordStyle(LexioColors.error).copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: LexioColors.error.withValues(alpha: 0.6),
              decorationThickness: 1.5,
            ),
          ),
        ),
        Positioned(
          top: -LexioSpacing.tokenCorrectionOffset,
          left: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: LexioDurations.feedback,
            curve: LexioCurves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * LexioSpacing.feedbackOffset),
                  child: child,
                ),
              );
            },
            child: Text(
              correction,
              style: LexioTextStyles.spotCorrection.copyWith(
                color: LexioColors.success,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShakingToken extends StatefulWidget {
  final String text;
  const _ShakingToken({required this.text});

  @override
  State<_ShakingToken> createState() => _ShakingTokenState();
}

class _CheckingToken extends StatelessWidget {
  final String original;
  final String correction;
  const _CheckingToken({required this.original, required this.correction});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(original, style: _wordStyle(LexioColors.textPrimary)),
        Text(
          original,
          style: _wordStyle(LexioColors.textSecondary).copyWith(
            decoration: TextDecoration.lineThrough,
            decorationColor: LexioColors.textSecondary.withValues(alpha: 0.5),
            decorationThickness: 1.5,
          ),
        ),
        Positioned(
          top: -LexioSpacing.tokenCorrectionOffset,
          left: 0,
          right: 0,
          child: Text(
            correction,
            style: LexioTextStyles.spotCorrection.copyWith(
              color: LexioColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _ShakingTokenState extends State<_ShakingToken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: LexioDurations.shake,
      vsync: this,
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: 4), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 4, end: -3), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -3, end: 2), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 2, end: -1), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -1, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: LexioCurves.easeInOut),
        );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Text(widget.text, style: _wordStyle(LexioColors.textPrimary)),
        );
      },
    );
  }
}
