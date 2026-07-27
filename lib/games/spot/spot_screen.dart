import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/animations.dart';
import '../../design/colors.dart';
import '../../design/components/lexio_button.dart';
import '../../design/components/lexio_card.dart';
import '../../design/components/lexio_feedback.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import 'spot_content.dart';
import 'spot_game.dart';
import 'widgets/spot_summary.dart';
import 'widgets/text_token.dart';

class SpotScreen extends StatefulWidget {
  final SpotGameMode mode;

  const SpotScreen({super.key, this.mode = SpotGameMode.normal});

  @override
  State<SpotScreen> createState() => _SpotScreenState();
}

class _SpotScreenState extends State<SpotScreen> {
  SpotGameState? _state;
  bool _isLoading = true;
  Timer? _timer;
  SpotMistake? _lastFoundMistake;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await SpotContent.load();
    final texts = SpotContent.session(5);
    setState(() {
      _state = SpotGameState(texts: texts, mode: widget.mode);
      _isLoading = false;
    });
    if (widget.mode == SpotGameMode.timed) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state == null || _state!.isFinished) {
        _timer?.cancel();
        return;
      }
      setState(() {
        _state = _state!.tick();
        if (_state!.isFinished) {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTapWord(int wordIndex) {
    if (_state == null) return;

    final outcome = _state!.tapWord(wordIndex);

    if (outcome.result == SpotTapResult.found) {
      HapticFeedback.lightImpact();
      setState(() {
        _state = outcome.state;
        _lastFoundMistake = outcome.mistake;
      });
    } else if (outcome.result == SpotTapResult.incorrect) {
      HapticFeedback.heavyImpact();
      setState(() {
        _state = outcome.state;
      });
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) {
          setState(() {
            _state = _state!.clearShaker();
          });
        }
      });
    }
  }

  void _handleNextText() {
    setState(() {
      _state = _state!.nextText();
      _lastFoundMistake = null;
    });
  }

  void _handlePlayAgain() {
    _timer?.cancel();
    final texts = SpotContent.session(5);
    setState(() {
      _state = SpotGameState(texts: texts, mode: widget.mode);
      _lastFoundMistake = null;
    });
    if (widget.mode == SpotGameMode.timed) {
      _startTimer();
    }
  }

  void _handleBack() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: LexioColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final state = _state!;
    if (state.isFinished) {
      return _buildSummary(state);
    }

    return _buildPlaying(state);
  }

  Widget _buildSummary(SpotGameState state) {
    return Scaffold(
      backgroundColor: LexioColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleBack,
        ),
      ),
      body: SpotSummary(
        state: state,
        onPlayAgain: _handlePlayAgain,
        onBack: _handleBack,
      ),
    );
  }

  Widget _buildPlaying(SpotGameState state) {
    return Scaffold(
      backgroundColor: LexioColors.background,
      appBar: _buildAppBar(state),
      body: Column(
        children: [
          _buildProgressBar(state),
          _buildFeedbackBar(state),
          Expanded(child: _buildTextArea(state)),
          _buildBottomBar(state),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(SpotGameState state) {
    final isTimed = state.mode == SpotGameMode.timed;

    return AppBar(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _handleBack,
      ),
      title: Column(
        children: [
          Text(
            'Găsește greșeala',
            style: LexioTextStyles.labelLarge.copyWith(
              color: LexioColors.textPrimary,
            ),
          ),
          if (isTimed)
            Text(
              _formatTime(state.remainingSeconds),
              style: LexioTextStyles.headingSmall.copyWith(
                color: state.remainingSeconds <= 10
                    ? LexioColors.error
                    : LexioColors.accent,
              ),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (!isTimed)
          Padding(
            padding: const EdgeInsets.only(right: LexioSpacing.sm),
            child: Center(
              child: Text(
                'Text ${state.currentTextIndex + 1}/${state.texts.length}',
                style: LexioTextStyles.bodySmall.copyWith(
                  color: LexioColors.textSecondary,
                ),
              ),
            ),
          ),
        if (isTimed)
          Padding(
            padding: const EdgeInsets.only(right: LexioSpacing.sm),
            child: Center(
              child: Text(
                'Text ${state.currentTextIndex + 1}',
                style: LexioTextStyles.bodySmall.copyWith(
                  color: LexioColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar(SpotGameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LexioSpacing.screenHorizontal,
        vertical: LexioSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: LexioColors.textSecondary,
          ),
          const SizedBox(width: LexioSpacing.xs),
          Text(
            'Găsit ${state.mistakesFound} / ${state.totalMistakesInCurrentText} greșeli',
            style: LexioTextStyles.labelSmall.copyWith(
              color: state.allMistakesFoundInCurrentText
                  ? LexioColors.success
                  : LexioColors.textSecondary,
            ),
          ),
          const Spacer(),
          _buildMiniDots(state),
        ],
      ),
    );
  }

  Widget _buildMiniDots(SpotGameState state) {
    final found = state.foundMistakeIndices[state.currentTextIndex];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(state.totalMistakesInCurrentText, (i) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: found.contains(i)
                ? LexioColors.success
                : LexioColors.textTertiary,
          ),
        );
      }),
    );
  }

  Widget _buildFeedbackBar(SpotGameState state) {
    if (_lastFoundMistake == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LexioSpacing.screenHorizontal,
        vertical: LexioSpacing.xs,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: LexioDurations.normal,
        curve: LexioCurves.smooth,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 8),
              child: child,
            ),
          );
        },
        child: LexioFeedback(
          type: LexioFeedbackType.success,
          message: _lastFoundMistake!.explanation,
        ),
      ),
    );
  }

  Widget _buildTextArea(SpotGameState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: LexioSpacing.screenHorizontal,
        vertical: LexioSpacing.md,
      ),
      child: LexioCard(
        padding: const EdgeInsets.all(LexioSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextTypeLabel(state),
            const SizedBox(height: LexioSpacing.md),
            _buildWordTokens(state),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTypeLabel(SpotGameState state) {
    String label;
    IconData icon;

    switch (state.currentText.type) {
      case 'whatsapp':
        label = 'Conversație';
        icon = Icons.chat_bubble_outline;
        break;
      case 'email':
        label = 'Email';
        icon = Icons.email_outlined;
        break;
      case 'story':
        label = 'Poveste';
        icon = Icons.auto_stories;
        break;
      case 'news':
        label = 'Știre';
        icon = Icons.article_outlined;
        break;
      default:
        label = 'Text';
        icon = Icons.text_fields;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: LexioColors.textTertiary),
        const SizedBox(width: LexioSpacing.xs),
        Text(
          label,
          style: LexioTextStyles.labelSmall.copyWith(
            color: LexioColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildWordTokens(SpotGameState state) {
    final words = state.currentText.words;
    final builders = <Widget>[];
    final shakerIndex = state.shakingWordIndex;

    for (int i = 0; i < words.length; i++) {
      TextTokenState tokenState;
      if (state.isFoundMistakeWord(i)) {
        tokenState = TextTokenState.found;
      } else if (shakerIndex == i) {
        tokenState = TextTokenState.shaking;
      } else {
        tokenState = TextTokenState.normal;
      }

      builders.add(
        TextToken(
          key: ValueKey('${state.currentTextIndex}_$i'),
          text: state.displayedWord(i),
          state: tokenState,
          onTap: state.isFoundMistakeWord(i) ? null : () => _handleTapWord(i),
        ),
      );
    }

    return Wrap(
      spacing: 2,
      runSpacing: 0,
      children: builders,
    );
  }

  Widget _buildBottomBar(SpotGameState state) {
    if (!state.allMistakesFoundInCurrentText) {
      return const SizedBox(height: LexioSpacing.xxl);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LexioSpacing.screenHorizontal,
        vertical: LexioSpacing.lg,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: LexioDurations.normal,
        curve: LexioCurves.bouncy,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: LexioButton(
          label: state.isLastText ? 'Vezi rezumatul' : 'Continuă',
          variant: LexioButtonVariant.primary,
          icon: state.isLastText ? Icons.emoji_events : Icons.arrow_forward,
          isExpanded: true,
          onPressed: _handleNextText,
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
