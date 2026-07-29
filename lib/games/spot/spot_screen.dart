import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/colors.dart';
import '../../design/components/lexio_button.dart';
import '../../design/components/lexio_feedback.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import 'spot_content.dart';
import 'spot_game.dart';
import 'widgets/spot_summary.dart';
import 'widgets/text_token.dart';

class SpotScreen extends StatefulWidget {
  const SpotScreen({super.key});

  @override
  State<SpotScreen> createState() => _SpotScreenState();
}

class _SpotScreenState extends State<SpotScreen> {
  SpotGameState? _state;
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await SpotContent.load();
      final texts = SpotContent.session(5);
      if (!mounted) return;
      setState(() {
        _state = SpotGameState(texts: texts, mode: SpotGameMode.timed);
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      debugPrint('SpotScreen: failed to load content: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state == null || _state!.isFinished || _state!.isChecking) {
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
    if (_state == null || _state!.isChecking) return;

    final outcome = _state!.tapWord(wordIndex);

    if (outcome.result == SpotTapResult.found) {
      HapticFeedback.lightImpact();
      setState(() {
        _state = outcome.state;
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

  void _handleCheck() {
    setState(() {
      _state = _state!.checkAnswers();
    });
  }

  void _handleNextText() {
    setState(() {
      _state = _state!.nextText();
    });
  }

  void _handlePlayAgain() {
    _timer?.cancel();
    final texts = SpotContent.session(5);
    setState(() {
      _state = SpotGameState(texts: texts, mode: SpotGameMode.timed);
    });
    _startTimer();
  }

  void _handleBack() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: LexioColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LexioSpacing.screenHorizontal,
            ),
            child: LexioFeedback(
              type: LexioFeedbackType.error,
              message: 'Nu s-au putut încărca exercițiile',
              description:
                  'Verifică conexiunea la internet și încearcă din nou.',
              actionLabel: 'Reîncearcă',
              action: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _init();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: LexioColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _state == null) {
      return _buildErrorScreen();
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
      body: SafeArea(
        child: SpotSummary(
          state: state,
          onPlayAgain: _handlePlayAgain,
          onBack: _handleBack,
        ),
      ),
    );
  }

  Widget _buildPlaying(SpotGameState state) {
    return Scaffold(
      backgroundColor: LexioColors.background,
      appBar: _buildAppBar(state),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: LexioSpacing.xl),
              _buildTextEyebrow(state),
              const SizedBox(height: LexioSpacing.md),
              _buildParagraphs(state),
              const SizedBox(height: LexioSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(state),
    );
  }

  PreferredSizeWidget _buildAppBar(SpotGameState state) {
    return AppBar(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBack,
      ),
      title: Padding(
        padding: const EdgeInsets.only(right: LexioSpacing.screenHorizontal),
        child: _buildProgressSegments(state),
      ),
      titleSpacing: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: LexioSpacing.screenHorizontal),
          child: Text(
            _formatTime(state.remainingSeconds),
            style: LexioTextStyles.labelLarge.copyWith(
              color: state.remainingSeconds <= 10
                  ? LexioColors.error
                  : LexioColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSegments(SpotGameState state) {
    return Row(
      children: List.generate(state.texts.length, (i) {
        final isCompleted =
            state.foundMistakeIndices[i].length ==
            state.texts[i].mistakes.length;
        final isCurrent = i == state.currentTextIndex;

        Color color;
        if (isCompleted) {
          color = LexioColors.success;
        } else if (isCurrent) {
          color = LexioColors.primary;
        } else {
          color = LexioColors.surfaceTertiary;
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : LexioSpacing.xxs),
            child: Container(
              height: isCurrent ? 4 : 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextEyebrow(SpotGameState state) {
    final label = switch (state.currentText.type) {
      'email' => 'Email',
      'story' => 'Poveste',
      'news' => 'Știre',
      'child_composition' => 'Compunere',
      'professional' => 'Text profesional',
      'social_media' => 'Rețea socială',
      'blog' => 'Blog',
      _ => 'Text',
    };

    return Text(
      label.toUpperCase(),
      style: LexioTextStyles.labelSmall.copyWith(
        color: LexioColors.textTertiary,
        letterSpacing: 1.2,
        fontSize: 11,
      ),
    );
  }

  Widget _buildParagraphs(SpotGameState state) {
    final ranges = state.currentText.paragraphRanges;
    final children = <Widget>[];

    for (int p = 0; p < ranges.length; p++) {
      final start = ranges[p][0];
      final end = ranges[p][1];
      children.add(_buildWordTokens(state, start, end));
      if (p < ranges.length - 1) {
        children.add(const SizedBox(height: LexioSpacing.lg));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildWordTokens(SpotGameState state, int startIndex, int endIndex) {
    final builders = <Widget>[];
    final shakerIndex = state.shakingWordIndex;

    for (int i = startIndex; i <= endIndex; i++) {
      final mistake = state.currentText.mistakeStartingAt(i);
      final wordCount = mistake?.wordCount ?? 1;
      TextTokenState tokenState;
      if (state.isFoundMistakeWord(i)) {
        tokenState = TextTokenState.found;
      } else if (state.isChecking && state.isUnfoundMistakeWord(i)) {
        tokenState = TextTokenState.checking;
      } else if (shakerIndex == i) {
        tokenState = TextTokenState.shaking;
      } else {
        tokenState = TextTokenState.normal;
      }

      String correction = '';
      if (tokenState == TextTokenState.found ||
          tokenState == TextTokenState.checking) {
        correction = _getCorrectionForWord(state, i);
      }

      final tappable = !state.isFoundMistakeWord(i) && !state.isChecking;

      builders.add(
        TextToken(
          key: ValueKey('${state.currentTextIndex}_$i'),
          originalText: mistake?.token ?? state.displayedWord(i),
          correctionText: correction,
          state: tokenState,
          onTap: tappable ? () => _handleTapWord(i) : null,
        ),
      );
      i += wordCount - 1;
    }

    return Wrap(spacing: 2, runSpacing: 4, children: builders);
  }

  String _getCorrectionForWord(SpotGameState state, int wordIndex) {
    for (int i = 0; i < state.currentText.mistakes.length; i++) {
      if (state.currentText.mistakes[i].containsWordIndex(wordIndex)) {
        return state.currentText.mistakes[i].replacement;
      }
    }
    return '';
  }

  Widget _buildBottomBar(SpotGameState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LexioSpacing.screenHorizontal,
          LexioSpacing.md,
          LexioSpacing.screenHorizontal,
          LexioSpacing.lg,
        ),
        child: state.isChecking
            ? _buildNextButton(state)
            : state.allMistakesFoundInCurrentText
            ? _buildNextButton(state)
            : _buildPlayActions(state),
      ),
    );
  }

  Widget _buildNextButton(SpotGameState state) {
    return LexioButton(
      label: state.isLastText ? 'Vezi rezumatul' : 'Continuă',
      variant: LexioButtonVariant.primary,
      icon: state.isLastText ? Icons.emoji_events : Icons.arrow_forward,
      isExpanded: true,
      onPressed: _handleNextText,
    );
  }

  Widget _buildPlayActions(SpotGameState state) {
    final mistakesText =
        '${state.mistakesFound} / ${state.totalMistakesInCurrentText} greșeli';

    return Row(
      children: [
        Expanded(
          child: Text(
            mistakesText,
            style: LexioTextStyles.labelSmall.copyWith(
              color: LexioColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: LexioSpacing.md),
        LexioButton(
          label: 'Arată toate greșelile',
          variant: LexioButtonVariant.ghost,
          size: LexioButtonSize.small,
          onPressed: _handleCheck,
        ),
      ],
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
