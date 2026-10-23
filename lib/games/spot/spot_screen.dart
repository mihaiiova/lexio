import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../analytics/analytics_event.dart';
import '../../analytics/analytics_repository.dart';
import '../../design/colors.dart';
import '../../design/components/lexio_button.dart';
import '../../design/components/lexio_feedback.dart';
import '../../design/components/lexio_feedback_screen.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../../progress/user_progress.dart';
import '../../content/content_runtime.dart';
import 'spot_content.dart';
import 'spot_game.dart';
import 'widgets/spot_summary.dart';
import 'widgets/text_token.dart';

class SpotScreen extends StatefulWidget {
  const SpotScreen({
    super.key,
    this.texts,
    this.progressRepository,
    this.analytics,
    this.mode = SpotGameMode.timed,
    this.clock,
  });

  final List<SpotText>? texts;
  final ProgressRepository? progressRepository;
  final AnalyticsRepository? analytics;
  final SpotGameMode mode;
  final DateTime Function()? clock;

  @override
  State<SpotScreen> createState() => _SpotScreenState();
}

class _SpotScreenState extends State<SpotScreen> with WidgetsBindingObserver {
  SpotGameState? _state;
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _timer;
  ProgressRepository? _progress;
  bool _hasSavedSession = false;
  bool _roundStarted = false;
  bool _roundEnded = false;
  int? _renderedIndex;

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final texts = widget.texts;
    if (texts != null) {
      _state = SpotGameState(
        texts: texts,
        mode: widget.mode,
        startTime: _now(),
      );
      _progress = widget.progressRepository;
      _isLoading = false;
      _scheduleShown(start: true);
      _startTimer();
    } else {
      _init();
    }
  }

  @override
  void dispose() {
    unawaited(_progress?.flush());
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_progress?.flush());
    }
  }

  void _onResume() => _checkTimer();

  void _checkTimer() {
    final state = _state;
    if (state == null ||
        state.isFinished ||
        state.texts.isEmpty ||
        widget.mode != SpotGameMode.timed)
      return;
    final updated = state.checkTimerExpiry(now: _now());
    if (identical(updated, state)) return;
    setState(() => _state = updated);
    if (updated.isFinished) {
      _timer?.cancel();
      _finish(updated, reason: AnalyticsRoundEndReason.timeout);
    } else {
      _scheduleShown();
    }
  }

  Future<void> _init() async {
    try {
      await ContentRuntime.activatePending();
      await SpotContent.load();
      final progress =
          widget.progressRepository ?? await ProgressRepository.load();
      final texts = SpotContent.adaptiveSession(5, progress.forGame('spot'));
      if (!mounted) return;
      setState(() {
        _state = SpotGameState(
          texts: texts,
          mode: widget.mode,
          startTime: _now(),
        );
        _progress = progress;
        _isLoading = false;
      });
      _scheduleShown(start: true);
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
    if (_state == null ||
        _state!.texts.isEmpty ||
        widget.mode != SpotGameMode.timed)
      return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _checkTimer());
  }

  void _handleTapWord(int wordIndex) {
    if (_state == null ||
        _state!.isChecking ||
        _state!.isFinished ||
        _state!.allMistakesFoundInCurrentText ||
        _roundEnded ||
        _renderedIndex != _state!.currentTextIndex)
      return;
    if (widget.mode == SpotGameMode.timed &&
        _state!.remainingSecondsAt(_now()) == 0) {
      _checkTimer();
      return;
    }

    final outcome = _state!.tapWord(wordIndex);
    unawaited(
      widget.analytics?.spotAttempt(
        itemId: _state!.currentText.id,
        itemIndex: _state!.currentTextIndex,
        wordPosition: wordIndex,
        newlyCorrect: outcome.result == SpotTapResult.found,
        isWrong: outcome.result == SpotTapResult.incorrect,
        resolvesItem: outcome.state.allMistakesFoundInCurrentText,
      ),
    );

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
      _state = _state!.nextText(now: _now());
    });
    if (_state!.isFinished) {
      _finish(_state!);
    } else {
      _scheduleShown();
    }
  }

  Future<void> _handlePlayAgain() async {
    _endRound(AnalyticsRoundEndReason.restart);
    await ContentRuntime.activatePending();
    if (!mounted) return;
    _timer?.cancel();
    final texts =
        widget.texts ??
        SpotContent.adaptiveSession(
          5,
          _progress?.forGame('spot') ?? const GameProgress(),
        );
    setState(() {
      _state = SpotGameState(
        texts: texts,
        mode: widget.mode,
        startTime: _now(),
      );
      _hasSavedSession = false;
    });
    _roundStarted = false;
    _roundEnded = false;
    _renderedIndex = null;
    _scheduleShown(start: true);
    _startTimer();
  }

  void _handleBack() {
    _endRound(AnalyticsRoundEndReason.userBack);
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  void _finish(
    SpotGameState state, {
    AnalyticsRoundEndReason reason = AnalyticsRoundEndReason.completed,
  }) {
    _endRound(reason);
    _saveSessionProgress(state);
  }

  void _saveSessionProgress(SpotGameState state) {
    if (_hasSavedSession) return;
    _hasSavedSession = true;
    _progress?.recordAnswers(
      gameId: 'spot',
      notionResults: state.notionResults,
    );
  }

  Widget _buildEmptyScreen() {
    return LexioFeedbackScreen(
      backgroundColor: LexioColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(),
      ),
      type: LexioFeedbackType.error,
      message: 'Nu există texte disponibile',
      description: 'Conținutul local nu conține texte pentru această rundă.',
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: LexioColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Înapoi la jocuri',
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

  void _endRound(AnalyticsRoundEndReason reason) {
    if (!_roundStarted || _roundEnded) return;
    _roundEnded = true;
    unawaited(widget.analytics?.endRound(reason: reason));
  }

  void _scheduleShown({bool start = false}) {
    final state = _state;
    if (state == null || state.texts.isEmpty) return;
    final index = state.currentTextIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _roundEnded ||
          _state!.isFinished ||
          !identical(_state!.texts, state.texts) ||
          _state!.currentTextIndex != index)
        return;
      _renderedIndex = index;
      if (start) {
        _roundStarted = true;
        unawaited(
          widget.analytics?.startRound(
            gameId: 'spot',
            contentVersion: ContentRuntime.activeContentVersion,
          ),
        );
      }
      unawaited(
        widget.analytics?.itemShown(
          itemId: state.currentText.id,
          itemIndex: index,
        ),
      );
      if (state.allMistakesFoundInCurrentText) {
        unawaited(
          widget.analytics?.itemResolved(
            itemId: state.currentText.id,
            itemIndex: index,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) _endRound(AnalyticsRoundEndReason.userBack);
    },
    child: _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
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
    if (state.texts.isEmpty) {
      return _buildEmptyScreen();
    }
    if (state.isFinished) {
      return _buildSummary(state);
    }

    return _buildPlaying(state);
  }

  Widget _buildSummary(SpotGameState state) {
    return Scaffold(
      backgroundColor: LexioColors.background,
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
        tooltip: 'Înapoi la jocuri',
        onPressed: _handleBack,
      ),
      title: Padding(
        padding: const EdgeInsets.only(right: LexioSpacing.screenHorizontal),
        child: Semantics(
          label:
              'Progres: ${state.textsCompleted} din ${state.texts.length} texte',
          child: _buildProgressSegments(state),
        ),
      ),
      titleSpacing: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: LexioSpacing.screenHorizontal),
          child: Semantics(
            label:
                'Timp rămas: ${_formatTime(state.remainingSecondsAt(_now()))}',
            liveRegion: true,
            child: Text(
              _formatTime(state.remainingSecondsAt(_now())),
              style: LexioTextStyles.labelLarge.copyWith(
                color: state.remainingSecondsAt(_now()) <= 10
                    ? LexioColors.error
                    : LexioColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSegments(SpotGameState state) {
    return Row(
      children: List.generate(state.texts.length, (i) {
        final isCompleted = state.isTextCompleted(i);
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

      final tappable =
          !state.isChecking && !state.allMistakesFoundInCurrentText;

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
      semanticLabel: state.isLastText
          ? 'Vezi rezumatul jocului'
          : 'Continuă la textul următor',
      variant: LexioButtonVariant.primary,
      icon: state.isLastText ? Icons.emoji_events : Icons.arrow_forward,
      isExpanded: true,
      onPressed: _handleNextText,
    );
  }

  Widget _buildPlayActions(SpotGameState state) {
    final mistakesText =
        '${state.mistakesFound} / ${state.totalMistakesInCurrentText} greșeli';

    return Wrap(
      spacing: LexioSpacing.md,
      runSpacing: LexioSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          mistakesText,
          style: LexioTextStyles.labelSmall.copyWith(
            color: LexioColors.textSecondary,
          ),
        ),
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
