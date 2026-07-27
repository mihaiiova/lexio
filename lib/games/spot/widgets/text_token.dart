import 'package:flutter/material.dart';

import '../../../design/animations.dart';
import '../../../design/colors.dart';
import '../../../design/radius.dart';
import '../../../design/typography.dart';

enum TextTokenState { normal, found, shaking }

class TextToken extends StatelessWidget {
  final String text;
  final TextTokenState state;
  final VoidCallback? onTap;

  const TextToken({
    super.key,
    required this.text,
    this.state = TextTokenState.normal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 3),
      child: GestureDetector(
        onTap: state == TextTokenState.found ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (state) {
      case TextTokenState.normal:
        return _NormalToken(text: text);
      case TextTokenState.found:
        return _FoundToken(text: text);
      case TextTokenState.shaking:
        return _ShakingToken(text: text);
    }
  }
}

class _NormalToken extends StatelessWidget {
  final String text;
  const _NormalToken({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LexioRadius.sm),
      ),
      child: Text(
        text,
        style: LexioTextStyles.bodyLarge.copyWith(
          color: LexioColors.textPrimary,
        ),
      ),
    );
  }
}

class _FoundToken extends StatelessWidget {
  final String text;
  const _FoundToken({required this.text});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: LexioDurations.fast,
      curve: LexioCurves.bouncy,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: LexioColors.successBackground,
          borderRadius: BorderRadius.circular(LexioRadius.sm),
          border: Border.all(
            color: LexioColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          text,
          style: LexioTextStyles.bodyLarge.copyWith(
            color: LexioColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ShakingToken extends StatefulWidget {
  final String text;
  const _ShakingToken({required this.text});

  @override
  State<_ShakingToken> createState() => _ShakingTokenState();
}

class _ShakingTokenState extends State<_ShakingToken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 3, end: -2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -2, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              color: LexioColors.errorBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(LexioRadius.sm),
            ),
            child: Text(
              widget.text,
              style: LexioTextStyles.bodyLarge.copyWith(
                color: LexioColors.error.withValues(alpha: 0.7),
              ),
            ),
          ),
        );
      },
    );
  }
}
