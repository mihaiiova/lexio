import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../../design/radius.dart';
import '../../design/animations.dart';
import '../../design/components/lexio_answer_button.dart';
import '../../design/components/lexio_feedback.dart';
import '../../progress/user_progress.dart';
import 'grammar_content.dart';
import 'grammar_game.dart';
import 'widgets/grammar_summary.dart';
import 'widgets/question_card.dart';
import 'widgets/result_overlay.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  GrammarGameState? _state;
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasAnswered = false;
  bool _showingExplanation = false;
  bool _showCorrectFlash = false;
  Key _flashKey = UniqueKey();
  ProgressRepository? _progress;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await GrammarContent.load();
      final progress = await ProgressRepository.load();
      final exercises = GrammarContent.adaptiveRound(
        15,
        progress.forGame('grammar'),
      );
      if (!mounted) return;
      setState(() {
        _state = GrammarGameState(exercises: exercises);
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('GrammarScreen: failed to load content: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _answer(bool playerSaysCorrect) {
    if (_hasAnswered || _state == null) return;
    final updated = _state!.answer(playerSaysCorrect);
    final isRight = updated.lastAnswerCorrect ?? false;

    if (isRight) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    final exercise = updated.currentExercise;
    _progress?.recordAnswer(
      gameId: 'grammar',
      notionId: exercise.notionId,
      isCorrect: isRight,
    );

    setState(() {
      _state = updated;
      _hasAnswered = true;
      _flashKey = UniqueKey();

      if (isRight) {
        _showCorrectFlash = true;
      } else {
        _showingExplanation = true;
      }
    });
  }

  void _advance() {
    if (_state == null) return;
    final updated = _state!.next();
    setState(() {
      _state = updated;
      _hasAnswered = false;
      _showingExplanation = false;
      _showCorrectFlash = false;
    });
  }

  void _next() {
    _advance();
  }

  void _playAgain() {
    final progress = _progress;
    if (progress == null) return;
    setState(() {
      _state = GrammarGameState(
        exercises: GrammarContent.adaptiveRound(
          15,
          progress.forGame('grammar'),
        ),
      );
      _hasAnswered = false;
      _showingExplanation = false;
      _showCorrectFlash = false;
      _flashKey = UniqueKey();
    });
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: LexioColors.surface,
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: LexioColors.surface,
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
      return const Scaffold(
        backgroundColor: LexioColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _state == null) {
      return _buildErrorScreen();
    }

    final state = _state!;

    if (state.isFinished) {
      return Scaffold(
        backgroundColor: LexioColors.surface,
        body: GrammarSummary(
          state: state,
          onPlayAgain: _playAgain,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: LexioColors.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: _buildProgressBar(state),
        titleSpacing: 0,
        backgroundColor: LexioColors.surface,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final state = _state!;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: _showingExplanation
                ? _buildResultView(state)
                : _buildQuestionView(state),
          ),
          if (_showingExplanation)
            _buildNextButton()
          else
            _buildBottomButtons(state),
        ],
      ),
    );
  }

  Widget _buildProgressBar(GrammarGameState state) {
    return Padding(
      padding: const EdgeInsets.only(right: LexioSpacing.screenHorizontal),
      child: Semantics(
        label: 'Progres: ${state.totalAnswered} din ${state.exercises.length}',
        child: Row(
        children: List.generate(state.exercises.length, (i) {
          final result = state.results[i];
          final isCurrent = i == state.currentIndex && result == null;

          Color color;
          if (result == true) {
            color = LexioColors.success;
          } else if (result == false) {
            color = LexioColors.error;
          } else if (isCurrent) {
            color = LexioColors.primary;
          } else {
            color = LexioColors.surfaceTertiary;
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : LexioSpacing.xxs),
              child: AnimatedContainer(
                duration: LexioDurations.fast,
                height: isCurrent ? 4 : 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(LexioRadius.sm),
                ),
              ),
            ),
          );
        }),
      ),
      ),
    );
  }

  Widget _buildBottomButtons(GrammarGameState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LexioSpacing.screenHorizontal,
        LexioSpacing.md,
        LexioSpacing.screenHorizontal,
        LexioSpacing.xl,
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LexioAnswerButton(
                label: 'Corect',
                tone: LexioAnswerButtonTone.positive,
                onPressed: _hasAnswered ? null : () => _answer(true),
                state: _hasAnswered
                    ? LexioAnswerButtonState.disabled
                    : LexioAnswerButtonState.idle,
              ),
              const SizedBox(height: LexioSpacing.md),
              LexioAnswerButton(
                label: 'Gre\u0219it',
                tone: LexioAnswerButtonTone.negative,
                onPressed: _hasAnswered ? null : () => _answer(false),
                state: _hasAnswered
                    ? LexioAnswerButtonState.disabled
                    : LexioAnswerButtonState.idle,
              ),
            ],
          ),
          if (_showCorrectFlash)
            TweenAnimationBuilder<double>(
              key: _flashKey,
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: LexioCurves.bouncy,
              onEnd: () {
                if (mounted) _advance();
              },
              builder: (context, value, child) {
                return Center(
                  child: Transform.scale(
                    scale: 0.5 + value * 1.5,
                    child: Opacity(
                      opacity: (1 - value).clamp(0.0, 1.0),
                      child: const Icon(
                        Icons.check,
                        size: 80,
                        color: LexioColors.success,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionView(GrammarGameState state) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: LexioSpacing.screenHorizontal,
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: LexioDurations.fast,
          curve: LexioCurves.easeOut,
          key: ValueKey(state.currentIndex),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: child,
              ),
            );
          },
          child: QuestionCard(sentence: state.currentExercise.sentence),
        ),
      ),
    );
  }

  Widget _buildResultView(GrammarGameState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ResultOverlay(exercise: state.currentExercise),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LexioSpacing.screenHorizontal,
        LexioSpacing.md,
        LexioSpacing.screenHorizontal,
        LexioSpacing.xl,
      ),
      child: Semantics(
        button: true,
        label: 'Următoarea întrebare',
        child: GestureDetector(
        onTap: _next,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: LexioSpacing.md),
          decoration: BoxDecoration(
            color: LexioColors.primary,
            borderRadius: BorderRadius.circular(LexioRadius.lg),
            border: Border.all(
              color: LexioColors.primary,
              width: LexioSpacing.xxs,
            ),
          ),
          child: Text(
            'Urm\u0103toarea',
            style: LexioTextStyles.bodyMedium.copyWith(
              color: LexioColors.textOnPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      ),
    );
  }
}
