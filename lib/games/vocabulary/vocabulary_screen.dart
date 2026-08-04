import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/animations.dart';
import '../../design/colors.dart';
import '../../design/components/lexio_answer_button.dart';
import '../../design/components/lexio_feedback.dart';
import '../../design/components/lexio_incorrect_answer_card.dart';
import '../../design/radius.dart';
import '../../design/spacing.dart';
import '../../progress/user_progress.dart';
import 'vocabulary_content.dart';
import 'vocabulary_game.dart';
import 'widgets/vocabulary_sentence.dart';
import 'widgets/vocabulary_summary.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key, this.exercises});

  final List<VocabularyExercise>? exercises;

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  static const _roundSize = 10;

  VocabularyGameState? _state;
  bool _isLoading = true;
  bool _hasError = false;
  ProgressRepository? _progress;

  @override
  void initState() {
    super.initState();
    final exercises = widget.exercises;
    if (exercises != null) {
      _state = VocabularyGameState(exercises: exercises);
      _isLoading = false;
    } else {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      await VocabularyContent.load();
      final progress = await ProgressRepository.load();
      final exercises = VocabularyContent.adaptiveRound(
        _roundSize,
        progress.forGame('vocabulary'),
      );
      if (!mounted) return;
      setState(() {
        _state = VocabularyGameState(exercises: exercises);
        _progress = progress;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('VocabularyScreen: failed to load content: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _answer(int optionIndex) {
    final state = _state;
    if (state == null || state.hasAnswered) return;

    final updated = state.answer(optionIndex);
    final exercise = updated.currentExercise;
    _progress?.recordAnswer(
      gameId: 'vocabulary',
      notionId: exercise.notionId,
      isCorrect: updated.lastAnswerCorrect ?? false,
    );
    if (updated.lastAnswerCorrect ?? false) {
      HapticFeedback.lightImpact();
      setState(() => _state = updated);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _state = updated.next());
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _state = updated);
    }
  }

  void _next() {
    final state = _state;
    if (state == null) return;
    setState(() => _state = state.next());
  }

  void _playAgain() {
    final suppliedExercises = widget.exercises;
    final exercises =
        suppliedExercises ??
        VocabularyContent.adaptiveRound(
          _roundSize,
          _progress?.forGame('vocabulary') ?? const GameProgress(),
        );
    setState(() => _state = VocabularyGameState(exercises: exercises));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: LexioColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _state == null || _state!.exercises.isEmpty) {
      return _buildErrorScreen();
    }

    final state = _state!;
    if (state.isFinished) {
      return Scaffold(
        backgroundColor: LexioColors.background,
        body: VocabularySummary(
          state: state,
          onPlayAgain: _playAgain,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: LexioColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: _buildProgressBar(state),
        titleSpacing: 0,
      ),
      body: SafeArea(top: false, child: _buildQuestion(state)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: LexioDurations.fast,
          child: state.lastAnswerCorrect == false
              ? _buildIncorrectPanel(state)
              : _buildActions(state),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: LexioColors.background,
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LexioSpacing.screenHorizontal,
            ),
            child: LexioFeedback(
              type: LexioFeedbackType.error,
              message: 'Nu s-au putut încărca exercițiile',
              description: 'Încearcă din nou peste câteva momente.',
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

  Widget _buildProgressBar(VocabularyGameState state) {
    return Padding(
      padding: const EdgeInsets.only(right: LexioSpacing.screenHorizontal),
      child: Row(
        children: List.generate(state.exercises.length, (index) {
          final result = state.results[index];
          final isCurrent = index == state.currentIndex && result == null;
          final color = switch (result) {
            true => LexioColors.success,
            false => LexioColors.error,
            null when isCurrent => LexioColors.primary,
            _ => LexioColors.divider,
          };

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : LexioSpacing.xxs),
              child: AnimatedContainer(
                duration: LexioDurations.fast,
                height: isCurrent ? LexioSpacing.xs : LexioSpacing.xxs,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(LexioRadius.sm),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuestion(VocabularyGameState state) {
    final exercise = state.currentExercise;

    return Center(
      child: SingleChildScrollView(
        key: ValueKey(exercise.id),
        padding: const EdgeInsets.symmetric(
          horizontal: LexioSpacing.screenHorizontal,
          vertical: LexioSpacing.xl,
        ),
        child: VocabularySentence(exercise: exercise),
      ),
    );
  }

  Widget _buildActions(VocabularyGameState state) {
    final exercise = state.currentExercise;
    return Padding(
      key: ValueKey('${exercise.id}_actions'),
      padding: const EdgeInsets.fromLTRB(
        LexioSpacing.screenHorizontal,
        LexioSpacing.md,
        LexioSpacing.screenHorizontal,
        LexioSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(exercise.options.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == exercise.options.length - 1
                  ? 0
                  : LexioSpacing.md,
            ),
            child: LexioAnswerButton(
              key: ValueKey('${exercise.id}_option_$index'),
              label: exercise.options[index],
              onPressed: state.hasAnswered ? null : () => _answer(index),
              state: _answerButtonState(state, index),
            ),
          );
        }),
      ),
    );
  }

  LexioAnswerButtonState _answerButtonState(
    VocabularyGameState state,
    int optionIndex,
  ) {
    if (!state.hasAnswered) return LexioAnswerButtonState.idle;
    if (optionIndex == state.currentExercise.correctOptionIndex) {
      return LexioAnswerButtonState.correct;
    }
    if (optionIndex == state.selectedOptionIndex) {
      return LexioAnswerButtonState.incorrect;
    }
    return LexioAnswerButtonState.disabled;
  }

  Widget _buildIncorrectPanel(VocabularyGameState state) {
    final exercise = state.currentExercise;

    return Padding(
      key: ValueKey('${exercise.id}_incorrect'),
      padding: const EdgeInsets.fromLTRB(
        LexioSpacing.screenHorizontal,
        LexioSpacing.md,
        LexioSpacing.screenHorizontal,
        LexioSpacing.xl,
      ),
      child: LexioIncorrectAnswerCard(
        subject: exercise.word,
        description: exercise.definition,
        details: 'Sinonime: ${exercise.synonyms.join(', ')}',
        onContinue: _next,
      ),
    );
  }
}
