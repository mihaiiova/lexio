import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../../design/radius.dart';
import '../../design/animations.dart';
import '../../design/components/lexio_button.dart';
import 'grammar_content.dart';
import 'grammar_game.dart';
import 'widgets/question_card.dart';
import 'widgets/answer_button.dart';
import 'widgets/result_overlay.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  GrammarGameState? _state;
  bool _isLoading = true;
  bool _hasAnswered = false;
  bool _showingExplanation = false;
  bool _showCorrectFlash = false;
  Key _flashKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    await GrammarContent.load();
    final exercises = GrammarContent.randomRound(15);
    setState(() {
      _state = GrammarGameState(exercises: exercises);
      _isLoading = false;
    });
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

      if (updated.isFinished) {
        _playAgain();
      }
    });
  }

  void _next() {
    _advance();
  }

  void _playAgain() {
    setState(() {
      _state = GrammarGameState(exercises: GrammarContent.randomRound(15));
      _hasAnswered = false;
      _showingExplanation = false;
      _showCorrectFlash = false;
      _flashKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _state == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final state = _state!;

    if (state.isFinished) {
      return Scaffold(
        backgroundColor: LexioColors.surface,
        appBar: AppBar(
          leading: const BackButton(),
          backgroundColor: LexioColors.surface,
        ),
        body: _buildSummaryContent(state),
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
          _buildTitle(),
          const SizedBox(height: LexioSpacing.xl),
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

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(
        left: LexioSpacing.screenHorizontal,
        top: LexioSpacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Corect sau gre\u0219it?',
          style: LexioTextStyles.headingSmall.copyWith(
            color: LexioColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(GrammarGameState state) {
    return Padding(
      padding: const EdgeInsets.only(right: LexioSpacing.screenHorizontal),
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
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : LexioSpacing.xxs,
              ),
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
              AnswerButton(
                label: 'Corect',
                isPositive: true,
                onTap: () => _answer(true),
                isDisabled: _hasAnswered,
              ),
              const SizedBox(height: LexioSpacing.md),
              AnswerButton(
                label: 'Gre\u0219it',
                isPositive: false,
                onTap: () => _answer(false),
                isDisabled: _hasAnswered,
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
          child: QuestionCard(
            sentence: state.currentExercise.sentence,
          ),
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
      child: GestureDetector(
        onTap: _next,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: LexioSpacing.lg),
          decoration: BoxDecoration(
            color: LexioColors.primary,
            borderRadius: BorderRadius.circular(LexioRadius.full),
            border: const Border(
              bottom: BorderSide(color: Colors.black26, width: 4),
            ),
          ),
          child: Text(
            'Urm\u0103toarea',
            style: LexioTextStyles.labelLarge.copyWith(
              color: LexioColors.textOnPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryContent(GrammarGameState state) {
    final wrongExercises = <GrammarExercise>[];
    for (var i = 0; i < state.exercises.length; i++) {
      if (state.results[i] == false) {
        wrongExercises.add(state.exercises[i]);
      }
    }

    final total = state.exercises.length;
    final correct = state.correctCount;
    final wrong = total - correct;
    final percentage = total == 0 ? 0 : (correct / total * 100).round();

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: LexioSpacing.screenHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: LexioSpacing.xl),
            Text(
              'Runda terminat\u0103',
              style: LexioTextStyles.headingLarge.copyWith(
                color: LexioColors.textPrimary,
              ),
            ),
            const SizedBox(height: LexioSpacing.xs),
            Text(
              '$correct din $total corecte \u2014 $percentage%',
              style: LexioTextStyles.bodyLarge.copyWith(
                color: wrong > 0 ? LexioColors.error : LexioColors.success,
              ),
            ),
            const SizedBox(height: LexioSpacing.xxxl),
            if (wrongExercises.isNotEmpty) ...[
              Text(
                'Gre\u0219eli ($wrong)',
                style: LexioTextStyles.labelSmall.copyWith(
                  color: LexioColors.textTertiary,
                ),
              ),
              const SizedBox(height: LexioSpacing.md),
              ...wrongExercises.map(_buildWrongItem),
              const SizedBox(height: LexioSpacing.xxl),
            ],
            LexioButton(
              label: 'Joac\u0103 din nou',
              onPressed: _playAgain,
              icon: Icons.replay,
            ),
            const SizedBox(height: LexioSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongItem(GrammarExercise exercise) {
    final doomUrl = exercise.doomUrl;
    final doomDef = exercise.doomDefinition;
    return Padding(
      padding: const EdgeInsets.only(bottom: LexioSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.sentence,
            style: LexioTextStyles.bodyLarge.copyWith(
              color: LexioColors.error,
              height: 1.5,
            ),
          ),
          if (exercise.correctSentence != null) ...[
            const SizedBox(height: LexioSpacing.xs),
            Text(
              exercise.correctSentence!,
              style: LexioTextStyles.bodyLarge.copyWith(
                color: LexioColors.success,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: LexioSpacing.sm),
          Text(
            exercise.explanation,
            style: LexioTextStyles.bodySmall.copyWith(
              color: LexioColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (doomDef != null) ...[
            const SizedBox(height: LexioSpacing.md),
            GestureDetector(
              onTap: doomUrl != null
                  ? () => launchUrl(
                        Uri.parse(doomUrl),
                        mode: LaunchMode.externalApplication,
                      )
                  : null,
              child: Container(
                padding: const EdgeInsets.all(LexioSpacing.md),
                decoration: BoxDecoration(
                  color: LexioColors.blueMuted,
                  borderRadius: BorderRadius.circular(LexioSpacing.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.menu_book,
                        size: 14,
                        color: LexioColors.primary,
                      ),
                    ),
                    const SizedBox(width: LexioSpacing.sm),
                    Expanded(
                      child: Text(
                        doomDef,
                        style: LexioTextStyles.bodySmall.copyWith(
                          color: LexioColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (doomUrl != null) ...[
            const SizedBox(height: LexioSpacing.md),
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(doomUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.menu_book,
                    size: 16,
                    color: LexioColors.primary,
                  ),
                  const SizedBox(width: LexioSpacing.xs),
                  Text(
                    'Vezi în DOOM',
                    style: LexioTextStyles.labelSmall.copyWith(
                      color: LexioColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

}
