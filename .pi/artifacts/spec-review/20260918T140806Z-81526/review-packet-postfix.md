# Code review packet

## Scope
Mode: branch review
Base: staging
HEAD: 0c258024fb24d94c217a888728e9a604342c0b29
Diff command: git diff staging...HEAD

## Commits
0c25802 fix(progress): preserve spot results during review (#46)
ca4c1f0 style(progress): order dart:async import first (#46)
6b37022 feat(progress): flush answers on background and close (#46)
09b6552 test(progress): cover rapid writes, retries, ordering, and failures (#46)
fc65def feat(progress): serialize writes and flush pending answers (#46)
63a4285 feat(progress): add injectable ProgressStorage read seam (#46)
7ec308b test(games): guard unanswered/finished next and correct-answer progress (#46)

## Changed files
M	lib/games/grammar/grammar_game.dart
M	lib/games/grammar/grammar_screen.dart
M	lib/games/idioms/idioms_game.dart
M	lib/games/idioms/idioms_screen.dart
M	lib/games/spot/spot_game.dart
M	lib/games/spot/spot_screen.dart
M	lib/games/vocabulary/vocabulary_game.dart
M	lib/games/vocabulary/vocabulary_screen.dart
M	lib/progress/user_progress.dart
M	test/games/grammar/grammar_game_test.dart
M	test/games/idioms/idioms_game_test.dart
M	test/games/spot/spot_game_test.dart
M	test/games/vocabulary/vocabulary_game_test.dart
A	test/progress/lifecycle_persistence_test.dart
A	test/progress/progress_repository_test.dart

## Diff stat
 lib/games/grammar/grammar_game.dart             |   6 +-
 lib/games/grammar/grammar_screen.dart           |  19 ++-
 lib/games/idioms/idioms_game.dart               |   2 +-
 lib/games/idioms/idioms_screen.dart             |  26 ++-
 lib/games/spot/spot_game.dart                   |  34 +++-
 lib/games/spot/spot_screen.dart                 |  24 ++-
 lib/games/vocabulary/vocabulary_game.dart       |   2 +-
 lib/games/vocabulary/vocabulary_screen.dart     |  30 +++-
 lib/progress/user_progress.dart                 |  66 ++++++--
 test/games/grammar/grammar_game_test.dart       |  30 +++-
 test/games/idioms/idioms_game_test.dart         |  13 +-
 test/games/spot/spot_game_test.dart             |  30 +++-
 test/games/vocabulary/vocabulary_game_test.dart |  13 +-
 test/progress/lifecycle_persistence_test.dart   | 100 ++++++++++++
 test/progress/progress_repository_test.dart     | 200 ++++++++++++++++++++++++
 15 files changed, 538 insertions(+), 57 deletions(-)

## Spec (GitHub issue #46)
## Parent

[Epic: Release-readiness hardening and regression coverage](https://github.com/mihaiiova/lexio/issues/45)

# Problem Statement
The current tree reports passing `flutter analyze` and 169 tests, but it contains uncommitted changes and a known persistence risk: progress writes are asynchronous, futures are ignored by screens, and flushing currently depends on navigating Back. The existing diff also includes changes to analyzer exclusions and the macOS deployment target whose intent is not documented.

# Solution
- Require an explicit review/disposition of the current working-tree diff before implementation: commit approved baseline changes separately or revert them; do not silently fold unrelated analyzer exclusions or the macOS deployment-target bump into this work.
- Re-run `flutter analyze`, `flutter test`, and `python3 scripts/validate_content.py` from the agreed clean baseline, fixing failures rather than weakening checks.
- Preserve and verify the correct-answer progress and `SpotGameState.isTextCompleted` regressions already represented in the baseline.
- Make progress persistence durable across the critical answer → background/close path, including a deterministic flush/lifecycle seam, while preserving serialized writes and non-throwing storage failure behavior.
- Add regression tests for rapid answer sequences, failed writes/retries, flush ordering, and lifecycle-triggered persistence.

# User Stories
- As a learner, I do not lose an answer when the app is backgrounded or closed immediately afterward.
- As a maintainer, I can distinguish a clean verified baseline from new release-hardening changes.
- As a release owner, I have reproducible analyzer, test, and content-validation evidence.

# Implementation Decisions
- Use `ProgressStorage`, `ProgressRepository.recordAnswer`, `recordAnswers`, and `flush` as the persistence seams; do not add a second persistence mechanism.
- Use `GrammarGameState`, `IdiomsGameState`, `VocabularyGameState`, and `SpotGameState` for pure regression coverage.
- Preserve the existing serialized-write contract and error logging; define the lifecycle flush behavior through an injectable/testable seam where practical.
- Do not treat `analysis_options.yaml` native-directory exclusions or `MACOSX_DEPLOYMENT_TARGET` 12.0 as accepted solely because they are present in the diff.
- Before implementation, set spec `baseBranch` to `staging` and retain `releaseBranch` as `master`, matching `docs/releasing.md`.

# Testing Decisions
- Unit-test `ProgressRepository`, `ProgressStorage`, `recordAnswer`, `recordAnswers`, and `flush` with the existing controlled/failing storage fakes in `test/progress/progress_repository_test.dart`.
- Add deterministic tests for lifecycle/background persistence without relying on a real app kill.
- Cover guard behavior and progress semantics through the four immutable game-state classes and their public methods.
- Run `flutter analyze`, `flutter test`, and `python3 scripts/validate_content.py`; record command results and test count in the implementation/review evidence.

# Out of Scope
- Store submission, signing, screenshots, analytics instrumentation expansion, or privacy copy unless this child exposes a concrete release-blocking failure.
- Committing or reverting the current working tree during `/spec-new`; baseline cleanup is a precondition for `/spec-start`.

# Further Notes
The requested user decision is to commit the current approved work so implementation starts from a clean baseline. This must happen outside the planning-only boundary, after reviewing the unrelated analyzer/macOS changes.

## Blocked by

None — can start immediately.

<!-- pi:new-spec:v2 repo=mihaiiova/lexio plan=4eaf4e48-1ee7-4a4e-a7bd-0a1e9d0a3e88 kind=child id=stabilize-verification-progress-durability -->

## Verification
- /Users/m/dev/pi-config/scripts/spec/run-checks.sh --check analyze=flutter analyze --check test=flutter test --check content=python3 scripts/validate_content.py: PASS (all three checks; test suite passed).
- Targeted regression tests: PASS (40 tests).
- `flutter analyze`: PASS, No issues found.
- `flutter test`: PASS, 134 tests.
- `python3 scripts/validate_content.py`: PASS.

## Patch
diff --git a/lib/games/grammar/grammar_game.dart b/lib/games/grammar/grammar_game.dart
index 8c1c0a4..9105648 100644
--- a/lib/games/grammar/grammar_game.dart
+++ b/lib/games/grammar/grammar_game.dart
@@ -1,71 +1,75 @@
 import 'grammar_content.dart';
 
 final class GrammarGameState {
   final List<GrammarExercise> exercises;
   final int currentIndex;
   final int correctCount;
   final int totalAnswered;
   final bool? lastAnswerCorrect;
   final bool isFinished;
   final List<bool?> results;
 
   GrammarGameState({
     required this.exercises,
     this.currentIndex = 0,
     this.correctCount = 0,
     this.totalAnswered = 0,
     this.lastAnswerCorrect,
     this.isFinished = false,
     List<bool?>? results,
   }) : results = results ?? List.filled(exercises.length, null);
 
   GrammarExercise get currentExercise => exercises[currentIndex];
 
   double get progress =>
-      exercises.isEmpty ? 0 : totalAnswered / exercises.length;
+      exercises.isEmpty ? 0 : correctCount / exercises.length;
 
   int get remaining => exercises.length - totalAnswered;
 
   GrammarGameState answer(bool playerSaysCorrect) {
+    if (isFinished || results[currentIndex] != null) return this;
+
     final actualCorrect = currentExercise.isCorrect;
     final isRight = playerSaysCorrect == actualCorrect;
 
     final newResults = List<bool?>.from(results);
     newResults[currentIndex] = isRight;
 
     return GrammarGameState(
       exercises: exercises,
       currentIndex: currentIndex,
       correctCount: isRight ? correctCount + 1 : correctCount,
       totalAnswered: totalAnswered + 1,
       lastAnswerCorrect: isRight,
       isFinished: false,
       results: newResults,
     );
   }
 
   GrammarGameState next() {
+    if (isFinished || results[currentIndex] == null) return this;
+
     final nextIndex = currentIndex + 1;
     if (nextIndex >= exercises.length) {
       return GrammarGameState(
         exercises: exercises,
         currentIndex: currentIndex,
         correctCount: correctCount,
         totalAnswered: totalAnswered,
         lastAnswerCorrect: null,
         isFinished: true,
         results: results,
       );
     }
 
     return GrammarGameState(
       exercises: exercises,
       currentIndex: nextIndex,
       correctCount: correctCount,
       totalAnswered: totalAnswered,
       lastAnswerCorrect: null,
       isFinished: false,
       results: results,
     );
   }
 }
diff --git a/lib/games/grammar/grammar_screen.dart b/lib/games/grammar/grammar_screen.dart
index ba2d050..38cbf27 100644
--- a/lib/games/grammar/grammar_screen.dart
+++ b/lib/games/grammar/grammar_screen.dart
@@ -1,127 +1,142 @@
+import 'dart:async';
+
 import 'package:flutter/material.dart';
 import 'package:flutter/services.dart';
 import '../../analytics/game_session_analytics.dart';
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
 
-class _GrammarScreenState extends State<GrammarScreen> {
+class _GrammarScreenState extends State<GrammarScreen>
+    with WidgetsBindingObserver {
   GrammarGameState? _state;
   bool _isLoading = true;
   bool _hasError = false;
   bool _hasAnswered = false;
   bool _showingExplanation = false;
   bool _showCorrectFlash = false;
   Key _flashKey = UniqueKey();
   ProgressRepository? _progress;
   final GameSessionAnalytics _session = GameSessionAnalytics('grammar');
 
   @override
   void initState() {
     super.initState();
+    WidgetsBinding.instance.addObserver(this);
     _init();
   }
 
   @override
   void dispose() {
+    unawaited(_progress?.flush());
+    WidgetsBinding.instance.removeObserver(this);
     _session.dispose();
     super.dispose();
   }
 
+  @override
+  void didChangeAppLifecycleState(AppLifecycleState state) {
+    if (state == AppLifecycleState.paused ||
+        state == AppLifecycleState.inactive ||
+        state == AppLifecycleState.detached) {
+      unawaited(_progress?.flush());
+    }
+  }
+
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
       _session.start();
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
     if (updated.isFinished) {
       _session.complete(updated.correctCount);
     }
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
@@ -155,161 +170,161 @@ class _GrammarScreenState extends State<GrammarScreen> {
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
-        label: 'Progres: ${state.totalAnswered} din ${state.exercises.length}',
+        label: 'Progres: ${state.correctCount} din ${state.exercises.length}',
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
diff --git a/lib/games/idioms/idioms_game.dart b/lib/games/idioms/idioms_game.dart
index d4617e7..1fcaa59 100644
--- a/lib/games/idioms/idioms_game.dart
+++ b/lib/games/idioms/idioms_game.dart
@@ -1,85 +1,85 @@
 import 'idioms_content.dart';
 
 final class IdiomsGameState {
   final List<IdiomExercise> exercises;
   final int currentIndex;
   final int correctCount;
   final int totalAnswered;
   final List<int?> selectedOptionIndices;
   final List<bool?> results;
   final bool isFinished;
 
   IdiomsGameState({
     required this.exercises,
     this.currentIndex = 0,
     this.correctCount = 0,
     this.totalAnswered = 0,
     List<int?>? selectedOptionIndices,
     List<bool?>? results,
     this.isFinished = false,
   }) : selectedOptionIndices =
            selectedOptionIndices ?? List<int?>.filled(exercises.length, null),
        results = results ?? List<bool?>.filled(exercises.length, null);
 
   IdiomExercise get currentExercise => exercises[currentIndex];
 
   int? get selectedOptionIndex => selectedOptionIndices[currentIndex];
 
   bool get hasAnswered => selectedOptionIndex != null;
 
   bool? get lastAnswerCorrect => hasAnswered
       ? selectedOptionIndex == currentExercise.correctOptionIndex
       : null;
 
   double get progress =>
-      exercises.isEmpty ? 0 : totalAnswered / exercises.length;
+      exercises.isEmpty ? 0 : correctCount / exercises.length;
 
   IdiomsGameState answer(int optionIndex) {
     if (hasAnswered ||
         optionIndex < 0 ||
         optionIndex >= currentExercise.options.length) {
       return this;
     }
 
     final isCorrect = optionIndex == currentExercise.correctOptionIndex;
     final updatedResults = List<bool?>.from(results);
     final updatedSelections = List<int?>.from(selectedOptionIndices);
     updatedResults[currentIndex] = isCorrect;
     updatedSelections[currentIndex] = optionIndex;
 
     return IdiomsGameState(
       exercises: exercises,
       currentIndex: currentIndex,
       correctCount: isCorrect ? correctCount + 1 : correctCount,
       totalAnswered: totalAnswered + 1,
       selectedOptionIndices: updatedSelections,
       results: updatedResults,
     );
   }
 
   IdiomsGameState next() {
     if (!hasAnswered) return this;
 
     final nextIndex = currentIndex + 1;
     if (nextIndex >= exercises.length) {
       return IdiomsGameState(
         exercises: exercises,
         currentIndex: currentIndex,
         correctCount: correctCount,
         totalAnswered: totalAnswered,
         selectedOptionIndices: selectedOptionIndices,
         results: results,
         isFinished: true,
       );
     }
 
     return IdiomsGameState(
       exercises: exercises,
       currentIndex: nextIndex,
       correctCount: correctCount,
       totalAnswered: totalAnswered,
       selectedOptionIndices: selectedOptionIndices,
       results: results,
     );
   }
 }
diff --git a/lib/games/idioms/idioms_screen.dart b/lib/games/idioms/idioms_screen.dart
index 2b26f07..a6dfa1f 100644
--- a/lib/games/idioms/idioms_screen.dart
+++ b/lib/games/idioms/idioms_screen.dart
@@ -1,287 +1,305 @@
+import 'dart:async';
+
 import 'package:flutter/material.dart';
 import 'package:flutter/services.dart';
 
 import '../../analytics/game_session_analytics.dart';
 import '../../design/animations.dart';
 import '../../design/colors.dart';
 import '../../design/components/lexio_answer_button.dart';
 import '../../design/components/lexio_feedback.dart';
 import '../../design/components/lexio_incorrect_answer_card.dart';
 import '../../design/radius.dart';
 import '../../design/spacing.dart';
 import '../../progress/user_progress.dart';
 import 'idioms_content.dart';
 import 'idioms_game.dart';
 import 'widgets/idiom_sentence.dart';
 import 'widgets/idioms_summary.dart';
 
 class IdiomsScreen extends StatefulWidget {
-  const IdiomsScreen({super.key, this.exercises});
+  const IdiomsScreen({super.key, this.exercises, this.progressRepository});
 
   final List<IdiomExercise>? exercises;
+  final ProgressRepository? progressRepository;
 
   @override
   State<IdiomsScreen> createState() => _IdiomsScreenState();
 }
 
-class _IdiomsScreenState extends State<IdiomsScreen> {
+class _IdiomsScreenState extends State<IdiomsScreen>
+    with WidgetsBindingObserver {
   static const _roundSize = 10;
 
   IdiomsGameState? _state;
   bool _isLoading = true;
   bool _hasError = false;
   ProgressRepository? _progress;
   final GameSessionAnalytics _session = GameSessionAnalytics('idioms');
 
   @override
   void initState() {
     super.initState();
+    WidgetsBinding.instance.addObserver(this);
     final exercises = widget.exercises;
     if (exercises != null) {
       _state = IdiomsGameState(exercises: exercises);
+      _progress = widget.progressRepository;
       _isLoading = false;
       _session.start();
     } else {
       _init();
     }
   }
 
   @override
   void dispose() {
+    unawaited(_progress?.flush());
+    WidgetsBinding.instance.removeObserver(this);
     _session.dispose();
     super.dispose();
   }
 
+  @override
+  void didChangeAppLifecycleState(AppLifecycleState state) {
+    if (state == AppLifecycleState.paused ||
+        state == AppLifecycleState.inactive ||
+        state == AppLifecycleState.detached) {
+      unawaited(_progress?.flush());
+    }
+  }
+
   Future<void> _init() async {
     try {
       await IdiomsContent.load();
-      final progress = await ProgressRepository.load();
+      final progress =
+          widget.progressRepository ?? await ProgressRepository.load();
       final exercises = IdiomsContent.adaptiveRound(
         _roundSize,
         progress.forGame('idioms'),
       );
       if (!mounted) return;
       setState(() {
         _state = IdiomsGameState(exercises: exercises);
         _progress = progress;
         _isLoading = false;
       });
       _session.start();
     } catch (error) {
       debugPrint('IdiomsScreen: failed to load content: $error');
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
       gameId: 'idioms',
       notionId: exercise.notionId,
       isCorrect: updated.lastAnswerCorrect ?? false,
     );
     if (updated.lastAnswerCorrect ?? false) {
       HapticFeedback.lightImpact();
       setState(() => _state = updated);
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (!mounted) return;
         final next = updated.next();
         setState(() => _state = next);
         if (next.isFinished) _session.complete(next.correctCount);
       });
     } else {
       HapticFeedback.heavyImpact();
       setState(() => _state = updated);
     }
   }
 
   void _next() {
     final state = _state;
     if (state == null) return;
     final next = state.next();
     setState(() => _state = next);
     if (next.isFinished) _session.complete(next.correctCount);
   }
 
   void _playAgain() {
     final suppliedExercises = widget.exercises;
     final exercises =
         suppliedExercises ??
         IdiomsContent.adaptiveRound(
           _roundSize,
           _progress?.forGame('idioms') ?? const GameProgress(),
         );
     setState(() => _state = IdiomsGameState(exercises: exercises));
     _session.start();
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
         body: IdiomsSummary(
           state: state,
           onPlayAgain: _playAgain,
           onBack: () => Navigator.of(context).maybePop(),
         ),
       );
     }
 
     return Scaffold(
       backgroundColor: LexioColors.background,
       appBar: AppBar(
         leading: Semantics(
           label: 'Înapoi la jocuri',
           child: BackButton(),
         ),
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
               message: 'Nu s-au putut încărca expresiile',
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
 
   Widget _buildProgressBar(IdiomsGameState state) {
     return Padding(
       padding: const EdgeInsets.only(right: LexioSpacing.screenHorizontal),
       child: Semantics(
-        label: 'Progres: ${state.totalAnswered} din ${state.exercises.length}',
+        label: 'Progres: ${state.correctCount} din ${state.exercises.length}',
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
       ),
     );
   }
 
   Widget _buildQuestion(IdiomsGameState state) {
     final exercise = state.currentExercise;
 
     return Center(
       child: SingleChildScrollView(
         key: ValueKey(exercise.id),
         padding: const EdgeInsets.symmetric(
           horizontal: LexioSpacing.screenHorizontal,
           vertical: LexioSpacing.xl,
         ),
         child: IdiomSentence(exercise: exercise),
       ),
     );
   }
 
   Widget _buildActions(IdiomsGameState state) {
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
     IdiomsGameState state,
     int optionIndex,
   ) {
diff --git a/lib/games/spot/spot_game.dart b/lib/games/spot/spot_game.dart
index 4c3b28a..aeefe74 100644
--- a/lib/games/spot/spot_game.dart
+++ b/lib/games/spot/spot_game.dart
@@ -1,143 +1,161 @@
 import 'spot_content.dart';
 
 enum SpotGameMode { normal, timed }
 
 enum SpotTapResult { found, incorrect, alreadyFound }
 
 final class SpotTapOutcome {
   final SpotGameState state;
   final SpotTapResult result;
   final SpotMistake? mistake;
 
   const SpotTapOutcome({
     required this.state,
     required this.result,
     this.mistake,
   });
 }
 
 final class SpotGameState {
   final List<SpotText> texts;
   final int currentTextIndex;
   final List<Set<int>> foundMistakeIndices;
   final List<Set<int>> incorrectTapWordIndices;
   final SpotGameMode mode;
   final DateTime startTime;
   final bool isFinished;
   final bool isChecking;
   final int? shakingWordIndex;
   final int? _frozenRemainingSeconds;
 
   static const _timerDuration = 60;
 
   SpotGameState({
     required this.texts,
     this.currentTextIndex = 0,
     List<Set<int>>? foundMistakeIndices,
     List<Set<int>>? incorrectTapWordIndices,
     this.mode = SpotGameMode.normal,
     DateTime? startTime,
     this.isFinished = false,
     this.isChecking = false,
     this.shakingWordIndex,
     this._frozenRemainingSeconds,
   }) : foundMistakeIndices =
            foundMistakeIndices ?? List.generate(texts.length, (_) => <int>{}),
        incorrectTapWordIndices =
            incorrectTapWordIndices ??
            List.generate(texts.length, (_) => <int>{}),
        startTime = startTime ?? DateTime.now();
 
   SpotText get currentText => texts[currentTextIndex];
-  int get mistakesFound => foundMistakeIndices[currentTextIndex].length;
-  int get totalMistakesInCurrentText => currentText.mistakes.length;
-  bool get allMistakesFoundInCurrentText =>
-      mistakesFound == totalMistakesInCurrentText;
-  bool get isLastText => currentTextIndex >= texts.length - 1;
+  int get mistakesFound =>
+      texts.isEmpty ? 0 : foundMistakeIndices[currentTextIndex].length;
+  int get totalMistakesInCurrentText =>
+      texts.isEmpty ? 0 : currentText.mistakes.length;
+  bool get allMistakesFoundInCurrentText => isTextCompleted(currentTextIndex);
+  bool get isLastText => texts.isEmpty || currentTextIndex >= texts.length - 1;
+
+  bool isTextCompleted(int textIndex) =>
+      texts.isNotEmpty &&
+      foundMistakeIndices[textIndex].length == texts[textIndex].mistakes.length;
+
+  Map<String, bool> get notionResults {
+    final results = <String, bool>{};
+    for (var textIndex = 0; textIndex < texts.length; textIndex++) {
+      final foundIndices = foundMistakeIndices[textIndex];
+      final text = texts[textIndex];
+      for (var mistakeIndex = 0;
+          mistakeIndex < text.mistakes.length;
+          mistakeIndex++) {
+        results[text.mistakes[mistakeIndex].notionId] =
+            foundIndices.contains(mistakeIndex);
+      }
+    }
+    return results;
+  }
 
   int get textsCompleted {
     int count = 0;
     for (int i = 0; i < texts.length; i++) {
-      if (foundMistakeIndices[i].length == texts[i].mistakes.length) {
-        count++;
-      }
+      if (isTextCompleted(i)) count++;
     }
     return count;
   }
 
   int get totalCorrectTaps {
     int sum = 0;
     for (final s in foundMistakeIndices) {
       sum += s.length;
     }
     return sum;
   }
 
   int get totalIncorrectTaps {
     int sum = 0;
     for (final s in incorrectTapWordIndices) {
       sum += s.length;
     }
     return sum;
   }
 
   int get totalTaps => totalCorrectTaps + totalIncorrectTaps;
 
   double get accuracy => totalTaps > 0 ? totalCorrectTaps / totalTaps : 1.0;
 
   Duration get elapsed => DateTime.now().difference(startTime);
 
   Duration elapsedAt(DateTime point) => point.difference(startTime);
 
   int get remainingSeconds {
     final secs = _timerDuration - elapsed.inSeconds;
     return secs < 0 ? 0 : secs;
   }
 
   int remainingSecondsAt(DateTime point) {
     final secs = _timerDuration - point.difference(startTime).inSeconds;
     return secs < 0 ? 0 : secs;
   }
 
   bool get isTimerExpired => remainingSeconds <= 0;
 
   int get score {
     final base = totalCorrectTaps * 100;
     final penalty = totalIncorrectTaps * 25;
     final bonusSeconds = _frozenRemainingSeconds ?? remainingSeconds;
     final timeBonus = mode == SpotGameMode.normal ? 0 : bonusSeconds * 5;
     return (base - penalty + timeBonus).clamp(0, 999999);
   }
 
   String displayedWord(int wordIndex) {
     return currentText.words[wordIndex];
   }
 
   bool isFoundMistakeWord(int wordIndex) {
     final found = foundMistakeIndices[currentTextIndex];
     for (int i = 0; i < currentText.mistakes.length; i++) {
       if (currentText.mistakes[i].containsWordIndex(wordIndex) &&
           found.contains(i)) {
         return true;
       }
     }
     return false;
   }
 
   bool isUnfoundMistakeWord(int wordIndex) {
     for (int i = 0; i < currentText.mistakes.length; i++) {
       if (currentText.mistakes[i].containsWordIndex(wordIndex) &&
           !foundMistakeIndices[currentTextIndex].contains(i)) {
         return true;
       }
     }
     return false;
   }
 
   SpotTapOutcome tapWord(int wordIndex) {
     if (isFinished) {
       return SpotTapOutcome(state: this, result: SpotTapResult.incorrect);
     }
 
     if (isFoundMistakeWord(wordIndex)) {
       return SpotTapOutcome(state: this, result: SpotTapResult.alreadyFound);
diff --git a/lib/games/spot/spot_screen.dart b/lib/games/spot/spot_screen.dart
index 3fa7e00..00c7a78 100644
--- a/lib/games/spot/spot_screen.dart
+++ b/lib/games/spot/spot_screen.dart
@@ -1,408 +1,404 @@
 import 'dart:async';
 
 import 'package:flutter/material.dart';
 import 'package:flutter/services.dart';
 
 import '../../analytics/game_session_analytics.dart';
 import '../../design/colors.dart';
 import '../../design/components/lexio_button.dart';
 import '../../design/components/lexio_feedback.dart';
 import '../../design/spacing.dart';
 import '../../design/typography.dart';
 import '../../progress/user_progress.dart';
 import 'spot_content.dart';
 import 'spot_game.dart';
 import 'widgets/spot_summary.dart';
 import 'widgets/text_token.dart';
 
 class SpotScreen extends StatefulWidget {
   const SpotScreen({super.key});
 
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
   final GameSessionAnalytics _session = GameSessionAnalytics('spot');
 
   @override
   void initState() {
     super.initState();
     WidgetsBinding.instance.addObserver(this);
     _init();
   }
 
   @override
   void dispose() {
+    unawaited(_progress?.flush());
     WidgetsBinding.instance.removeObserver(this);
     _timer?.cancel();
     _session.dispose();
     super.dispose();
   }
 
   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     if (state == AppLifecycleState.resumed) {
       _onResume();
+    } else if (state == AppLifecycleState.paused ||
+        state == AppLifecycleState.inactive ||
+        state == AppLifecycleState.detached) {
+      unawaited(_progress?.flush());
     }
   }
 
   void _onResume() {
     if (_state == null || _state!.isFinished) return;
     setState(() {
       final updated = _state!.checkTimerExpiry();
       if (updated != _state) {
         _state = updated;
         if (_state!.isFinished) {
           _timer?.cancel();
           _finish(_state!);
         }
       }
     });
   }
 
   Future<void> _init() async {
     try {
       await SpotContent.load();
       final progress = await ProgressRepository.load();
       final texts = SpotContent.adaptiveSession(5, progress.forGame('spot'));
       if (!mounted) return;
       setState(() {
         _state = SpotGameState(texts: texts, mode: SpotGameMode.timed);
         _progress = progress;
         _isLoading = false;
       });
       _session.start();
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
       if (_state == null || _state!.isFinished) {
         _timer?.cancel();
         return;
       }
       setState(() {
         final updated = _state!.checkTimerExpiry();
         if (updated != _state) {
           _state = updated;
           if (_state!.isFinished) {
             _timer?.cancel();
             _finish(_state!);
           }
         }
       });
     });
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
     if (_state!.isFinished) _finish(_state!);
   }
 
   void _handlePlayAgain() {
     _timer?.cancel();
     final texts = SpotContent.adaptiveSession(
       5,
       _progress?.forGame('spot') ?? const GameProgress(),
     );
     setState(() {
       _state = SpotGameState(texts: texts, mode: SpotGameMode.timed);
       _hasSavedSession = false;
     });
     _session.start();
     _startTimer();
   }
 
   void _handleBack() {
     _timer?.cancel();
     Navigator.of(context).pop();
   }
 
   void _finish(SpotGameState state) {
     _saveSessionProgress(state);
     _session.complete(state.score);
   }
 
   void _saveSessionProgress(SpotGameState state) {
     if (_hasSavedSession) return;
     _hasSavedSession = true;
-    final notionResults = <String, bool>{};
-    for (final text in state.texts) {
-      final index = state.texts.indexOf(text);
-      final foundIndices = state.foundMistakeIndices[index];
-      for (var i = 0; i < text.mistakes.length; i++) {
-        final notionId = text.mistakes[i].notionId;
-        final wasFound = foundIndices.contains(i);
-        notionResults[notionId] = wasFound;
-      }
-    }
-    _progress?.recordAnswers(gameId: 'spot', notionResults: notionResults);
+    _progress?.recordAnswers(
+      gameId: 'spot',
+      notionResults: state.notionResults,
+    );
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
             label: 'Timp rămas: ${_formatTime(state.remainingSeconds)}',
             liveRegion: true,
             child: Text(
               _formatTime(state.remainingSeconds),
               style: LexioTextStyles.labelLarge.copyWith(
                 color: state.remainingSeconds <= 10
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
-        final isCompleted =
-            state.foundMistakeIndices[i].length ==
-            state.texts[i].mistakes.length;
+        final isCompleted = state.isTextCompleted(i);
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
diff --git a/lib/games/vocabulary/vocabulary_game.dart b/lib/games/vocabulary/vocabulary_game.dart
index 51ef42b..a20afdc 100644
--- a/lib/games/vocabulary/vocabulary_game.dart
+++ b/lib/games/vocabulary/vocabulary_game.dart
@@ -1,85 +1,85 @@
 import 'vocabulary_content.dart';
 
 final class VocabularyGameState {
   final List<VocabularyExercise> exercises;
   final int currentIndex;
   final int correctCount;
   final int totalAnswered;
   final List<int?> selectedOptionIndices;
   final List<bool?> results;
   final bool isFinished;
 
   VocabularyGameState({
     required this.exercises,
     this.currentIndex = 0,
     this.correctCount = 0,
     this.totalAnswered = 0,
     List<int?>? selectedOptionIndices,
     List<bool?>? results,
     this.isFinished = false,
   }) : selectedOptionIndices =
            selectedOptionIndices ?? List<int?>.filled(exercises.length, null),
        results = results ?? List<bool?>.filled(exercises.length, null);
 
   VocabularyExercise get currentExercise => exercises[currentIndex];
 
   int? get selectedOptionIndex => selectedOptionIndices[currentIndex];
 
   bool get hasAnswered => selectedOptionIndex != null;
 
   bool? get lastAnswerCorrect => hasAnswered
       ? selectedOptionIndex == currentExercise.correctOptionIndex
       : null;
 
   double get progress =>
-      exercises.isEmpty ? 0 : totalAnswered / exercises.length;
+      exercises.isEmpty ? 0 : correctCount / exercises.length;
 
   VocabularyGameState answer(int optionIndex) {
     if (hasAnswered ||
         optionIndex < 0 ||
         optionIndex >= currentExercise.options.length) {
       return this;
     }
 
     final isCorrect = optionIndex == currentExercise.correctOptionIndex;
     final updatedResults = List<bool?>.from(results);
     final updatedSelections = List<int?>.from(selectedOptionIndices);
     updatedResults[currentIndex] = isCorrect;
     updatedSelections[currentIndex] = optionIndex;
 
     return VocabularyGameState(
       exercises: exercises,
       currentIndex: currentIndex,
       correctCount: isCorrect ? correctCount + 1 : correctCount,
       totalAnswered: totalAnswered + 1,
       selectedOptionIndices: updatedSelections,
       results: updatedResults,
     );
   }
 
   VocabularyGameState next() {
     if (!hasAnswered) return this;
 
     final nextIndex = currentIndex + 1;
     if (nextIndex >= exercises.length) {
       return VocabularyGameState(
         exercises: exercises,
         currentIndex: currentIndex,
         correctCount: correctCount,
         totalAnswered: totalAnswered,
         selectedOptionIndices: selectedOptionIndices,
         results: results,
         isFinished: true,
       );
     }
 
     return VocabularyGameState(
       exercises: exercises,
       currentIndex: nextIndex,
       correctCount: correctCount,
       totalAnswered: totalAnswered,
       selectedOptionIndices: selectedOptionIndices,
       results: results,
     );
   }
 }
diff --git a/lib/games/vocabulary/vocabulary_screen.dart b/lib/games/vocabulary/vocabulary_screen.dart
index 72061fe..6caa1f5 100644
--- a/lib/games/vocabulary/vocabulary_screen.dart
+++ b/lib/games/vocabulary/vocabulary_screen.dart
@@ -1,287 +1,309 @@
+import 'dart:async';
+
 import 'package:flutter/material.dart';
 import 'package:flutter/services.dart';
 
 import '../../analytics/game_session_analytics.dart';
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
-  const VocabularyScreen({super.key, this.exercises});
+  const VocabularyScreen({
+    super.key,
+    this.exercises,
+    this.progressRepository,
+  });
 
   final List<VocabularyExercise>? exercises;
+  final ProgressRepository? progressRepository;
 
   @override
   State<VocabularyScreen> createState() => _VocabularyScreenState();
 }
 
-class _VocabularyScreenState extends State<VocabularyScreen> {
+class _VocabularyScreenState extends State<VocabularyScreen>
+    with WidgetsBindingObserver {
   static const _roundSize = 10;
 
   VocabularyGameState? _state;
   bool _isLoading = true;
   bool _hasError = false;
   ProgressRepository? _progress;
   final GameSessionAnalytics _session = GameSessionAnalytics('vocabulary');
 
   @override
   void initState() {
     super.initState();
+    WidgetsBinding.instance.addObserver(this);
     final exercises = widget.exercises;
     if (exercises != null) {
       _state = VocabularyGameState(exercises: exercises);
+      _progress = widget.progressRepository;
       _isLoading = false;
       _session.start();
     } else {
       _init();
     }
   }
 
   @override
   void dispose() {
+    unawaited(_progress?.flush());
+    WidgetsBinding.instance.removeObserver(this);
     _session.dispose();
     super.dispose();
   }
 
+  @override
+  void didChangeAppLifecycleState(AppLifecycleState state) {
+    if (state == AppLifecycleState.paused ||
+        state == AppLifecycleState.inactive ||
+        state == AppLifecycleState.detached) {
+      unawaited(_progress?.flush());
+    }
+  }
+
   Future<void> _init() async {
     try {
       await VocabularyContent.load();
-      final progress = await ProgressRepository.load();
+      final progress =
+          widget.progressRepository ?? await ProgressRepository.load();
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
       _session.start();
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
         if (!mounted) return;
         final next = updated.next();
         setState(() => _state = next);
         if (next.isFinished) _session.complete(next.correctCount);
       });
     } else {
       HapticFeedback.heavyImpact();
       setState(() => _state = updated);
     }
   }
 
   void _next() {
     final state = _state;
     if (state == null) return;
     final next = state.next();
     setState(() => _state = next);
     if (next.isFinished) _session.complete(next.correctCount);
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
     _session.start();
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
         leading: Semantics(
           label: 'Înapoi la jocuri',
           child: BackButton(),
         ),
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
       child: Semantics(
-        label: 'Progres: ${state.totalAnswered} din ${state.exercises.length}',
+        label: 'Progres: ${state.correctCount} din ${state.exercises.length}',
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
diff --git a/lib/progress/user_progress.dart b/lib/progress/user_progress.dart
index bac6300..3159caf 100644
--- a/lib/progress/user_progress.dart
+++ b/lib/progress/user_progress.dart
@@ -1,235 +1,273 @@
 import 'dart:convert';
 import 'dart:math';
 
+import 'package:flutter/foundation.dart';
 import 'package:shared_preferences/shared_preferences.dart';
 
 import 'learning_item.dart';
 
 int _todayDay() {
   final now = DateTime.now();
   return DateTime.utc(now.year, now.month, now.day)
           .millisecondsSinceEpoch ~/
       Duration.millisecondsPerDay;
 }
 
 final class GameProgress {
   final Map<String, LearningItem> items;
 
   const GameProgress({this.items = const {}});
 
   LearningItem progressFor(String notionId) =>
       items[notionId] ?? LearningItem.newItem(notionId: notionId);
 
   int countOverdue(int today) =>
       items.values.where((item) => item.isOverdue(today)).length;
 
   int countEligible(int today) =>
       items.values.where((item) => item.isEligibleForReview(today)).length;
 
   GameProgress recordAnswer({
     required String notionId,
     required bool isCorrect,
     required int today,
   }) {
     final current = items[notionId] ?? LearningItem.newItem(notionId: notionId);
     final updated = current.recordAnswer(isCorrect: isCorrect, today: today);
     final updatedItems = Map<String, LearningItem>.from(items);
     updatedItems[notionId] = updated;
     return GameProgress(items: updatedItems);
   }
 
   Map<String, dynamic> toJson() => {
     'items': items.map((id, item) => MapEntry(id, item.toJson())),
   };
 
   factory GameProgress.fromJson(Map<String, dynamic> json) {
     final itemsJson = json['items'] as Map<String, dynamic>? ?? {};
     return GameProgress(
       items: itemsJson.map(
         (id, data) => MapEntry(
           id,
           LearningItem.fromJson(data as Map<String, dynamic>),
         ),
       ),
     );
   }
 }
 
 final class UserProgress {
   final Map<String, GameProgress> games;
 
   const UserProgress({this.games = const {}});
 
   GameProgress forGame(String gameId) =>
       games[gameId] ?? const GameProgress();
 
   UserProgress recordAnswer({
     required String gameId,
     required String notionId,
     required bool isCorrect,
     required int today,
   }) {
     final updatedGames = Map<String, GameProgress>.from(games);
     updatedGames[gameId] = forGame(gameId).recordAnswer(
       notionId: notionId,
       isCorrect: isCorrect,
       today: today,
     );
     return UserProgress(games: updatedGames);
   }
 
   String toJson() => jsonEncode({
     'games': games.map((id, progress) => MapEntry(id, progress.toJson())),
   });
 
   factory UserProgress.fromJson(String source) {
     final json = jsonDecode(source) as Map<String, dynamic>;
     final gamesJson = json['games'] as Map<String, dynamic>? ?? {};
     return UserProgress(
       games: gamesJson.map(
         (id, progress) => MapEntry(
           id,
           GameProgress.fromJson(progress as Map<String, dynamic>),
         ),
       ),
     );
   }
 }
 
+abstract class ProgressStorage {
+  Future<String?> read();
+  Future<void> write(String value);
+}
+
+final class SharedPreferencesProgressStorage implements ProgressStorage {
+  SharedPreferencesProgressStorage(
+    this._key, [
+    SharedPreferencesAsync? preferences,
+  ]) : _preferences = preferences ?? SharedPreferencesAsync();
+
+  final String _key;
+  final SharedPreferencesAsync _preferences;
+
+  @override
+  Future<String?> read() => _preferences.getString(_key);
+
+  @override
+  Future<void> write(String value) => _preferences.setString(_key, value);
+}
+
 final class ProgressRepository {
   static const _storageKey = 'user_progress_v2';
 
-  ProgressRepository._(this._preferences, this._progress);
+  ProgressRepository._(this._storage, this._progress);
 
-  final SharedPreferencesAsync? _preferences;
+  final ProgressStorage? _storage;
   UserProgress _progress;
+  Future<void> _writeQueue = Future<void>.value();
 
-  static Future<ProgressRepository> load() async {
-    SharedPreferencesAsync? preferences;
+  static Future<ProgressRepository> load({ProgressStorage? storage}) async {
+    ProgressStorage? effectiveStorage = storage;
     UserProgress progress;
     try {
-      preferences = SharedPreferencesAsync();
-      final source = await preferences.getString(_storageKey);
+      effectiveStorage ??= SharedPreferencesProgressStorage(_storageKey);
+      final source = await effectiveStorage.read();
       progress = source == null
           ? const UserProgress()
           : UserProgress.fromJson(source);
     } catch (_) {
-      preferences = null;
+      effectiveStorage = null;
       progress = const UserProgress();
     }
-    return ProgressRepository._(preferences, progress);
+    return ProgressRepository._(effectiveStorage, progress);
   }
 
   GameProgress forGame(String gameId) => _progress.forGame(gameId);
 
   Future<void> recordAnswer({
     required String gameId,
     required String notionId,
     required bool isCorrect,
-  }) async {
-    final today = _todayDay();
+  }) {
     _progress = _progress.recordAnswer(
       gameId: gameId,
       notionId: notionId,
       isCorrect: isCorrect,
-      today: today,
+      today: _todayDay(),
     );
-    await _preferences?.setString(_storageKey, _progress.toJson());
+    return _enqueueWrite();
   }
 
   Future<void> recordAnswers({
     required String gameId,
     required Map<String, bool> notionResults,
-  }) async {
+  }) {
     final today = _todayDay();
     var updated = _progress;
     for (final entry in notionResults.entries) {
       updated = updated.recordAnswer(
         gameId: gameId,
         notionId: entry.key,
         isCorrect: entry.value,
         today: today,
       );
     }
     _progress = updated;
-    await _preferences?.setString(_storageKey, _progress.toJson());
+    return _enqueueWrite();
+  }
+
+  Future<void> flush() => _writeQueue;
+
+  Future<void> _enqueueWrite() {
+    final storage = _storage;
+    if (storage == null) return Future<void>.value();
+    final snapshot = _progress.toJson();
+    _writeQueue = _writeQueue.then((_) async {
+      try {
+        await storage.write(snapshot);
+      } catch (error) {
+        debugPrint('ProgressRepository: failed to persist progress: $error');
+      }
+    });
+    return _writeQueue;
   }
 }
 
 final class RoundSelector {
   RoundSelector._();
 
   static List<T> select<T>({
     required List<T> exercises,
     required int count,
     required GameProgress progress,
     required String Function(T exercise) notionIdOf,
     Random? random,
     int? today,
   }) {
     if (count <= 0 || exercises.isEmpty) return [];
 
     final generator = random ?? Random();
     final effectiveToday = today ?? _todayDay();
     final selected = <T>[];
     final usedNotions = <String>{};
 
     final shuffled = List<T>.from(exercises)..shuffle(generator);
 
     final overdue = <T>[];
     final eligible = <T>[];
     final newItems = <T>[];
     final ineligible = <T>[];
 
     for (final exercise in shuffled) {
       final notionId = notionIdOf(exercise);
       final item = progress.progressFor(notionId);
       if (item.isOverdue(effectiveToday)) {
         overdue.add(exercise);
       } else if (item.state == LearningItemState.newItem) {
         newItems.add(exercise);
       } else if (item.isEligibleForReview(effectiveToday)) {
         eligible.add(exercise);
       } else {
         ineligible.add(exercise);
       }
     }
 
     _addFromBucket(overdue, selected, usedNotions, notionIdOf, count, generator);
     _addFromBucket(
       eligible,
       selected,
       usedNotions,
       notionIdOf,
       count,
       generator,
     );
     _addFromBucket(
       newItems,
       selected,
       usedNotions,
       notionIdOf,
       count,
       generator,
     );
     _addFromBucket(
       ineligible,
       selected,
       usedNotions,
       notionIdOf,
       count,
       generator,
     );
 
     if (selected.isEmpty && exercises.isNotEmpty) {
       return [exercises.first];
     }
 
     return selected.toList(growable: false);
   }
 
   static List<T> selectMultiNotion<T>({
     required List<T> exercises,
     required int count,
     required GameProgress progress,
     required List<String> Function(T exercise) notionIdsOf,
diff --git a/test/games/grammar/grammar_game_test.dart b/test/games/grammar/grammar_game_test.dart
index 98cd794..d246a74 100644
--- a/test/games/grammar/grammar_game_test.dart
+++ b/test/games/grammar/grammar_game_test.dart
@@ -1,102 +1,130 @@
 import 'package:flutter_test/flutter_test.dart';
 import 'package:lexio/games/grammar/grammar_game.dart';
 import 'package:lexio/games/grammar/grammar_content.dart';
 
 void main() {
   group('GrammarGameState', () {
     final exercises = [
       GrammarExercise(
         id: '1',
         sentence: 'Test corect.',
         category: 'acord',
         topic: 'acord',
         isCorrect: true,
         explanation: 'E corect.',
         correctSentence: null,
         difficulty: 1,
         tags: [],
         pairId: null,
       ),
       GrammarExercise(
         id: '2',
         sentence: 'Test gresit.',
         category: 'cratime',
         topic: 'cratime',
         isCorrect: false,
         explanation: 'E gre\u0219it.',
         correctSentence: 'Varianta bun\u0103.',
         difficulty: 2,
         tags: [],
         pairId: null,
       ),
     ];
 
     test('initial state has correct defaults', () {
       final state = GrammarGameState(exercises: exercises);
       expect(state.currentIndex, 0);
       expect(state.correctCount, 0);
       expect(state.totalAnswered, 0);
       expect(state.lastAnswerCorrect, isNull);
       expect(state.isFinished, false);
       expect(state.progress, 0);
       expect(state.remaining, 2);
     });
 
     test('currentExercise returns correct exercise', () {
       final state = GrammarGameState(exercises: exercises);
       expect(state.currentExercise.id, '1');
     });
 
     test('answer correctly identifies a correct answer', () {
       final state = GrammarGameState(exercises: exercises);
       final next = state.answer(true);
       expect(next.lastAnswerCorrect, true);
       expect(next.correctCount, 1);
       expect(next.totalAnswered, 1);
     });
 
     test('answer correctly identifies an incorrect answer', () {
       final state = GrammarGameState(exercises: exercises);
       final next = state.answer(false);
       expect(next.lastAnswerCorrect, false);
       expect(next.correctCount, 0);
       expect(next.totalAnswered, 1);
     });
 
+    test('answer ignores a second answer to the same exercise', () {
+      final state = GrammarGameState(exercises: exercises);
+      final answered = state.answer(true);
+
+      expect(answered.answer(false), same(answered));
+    });
+
     test('results tracks per-question outcomes', () {
       var state = GrammarGameState(exercises: exercises);
       state = state.answer(true);
       expect(state.results[0], true);
       state = state.next();
       state = state.answer(true);
       expect(state.results[1], false);
     });
 
     test('next advances to next exercise', () {
       var state = GrammarGameState(exercises: exercises);
       state = state.answer(true);
       state = state.next();
       expect(state.currentIndex, 1);
       expect(state.lastAnswerCorrect, isNull);
       expect(state.currentExercise.id, '2');
     });
 
     test('isFinished is true after answering all questions', () {
       var state = GrammarGameState(exercises: exercises);
       state = state.answer(true);
       state = state.next();
       state = state.answer(false);
       state = state.next();
       expect(state.isFinished, true);
     });
 
-    test('progress is 1.0 after all answered', () {
+    test('next ignores an incomplete or finished exercise', () {
+      final initial = GrammarGameState(exercises: exercises);
+      final answered = initial.answer(true);
+      final next = answered.next();
+      final finished = next.answer(false).next();
+
+      expect(initial.next(), same(initial));
+      expect(finished.next(), same(finished));
+    });
+
+    test('progress counts only correct answers', () {
+      var state = GrammarGameState(exercises: exercises);
+      state = state.answer(true);
+      state = state.next();
+      state = state.answer(true);
+      state = state.next();
+
+      expect(state.progress, 0.5);
+    });
+
+    test('progress is 1.0 after every answer is correct', () {
       var state = GrammarGameState(exercises: exercises);
       state = state.answer(true);
       state = state.next();
       state = state.answer(false);
       state = state.next();
+
       expect(state.progress, 1.0);
     });
   });
 }
diff --git a/test/games/idioms/idioms_game_test.dart b/test/games/idioms/idioms_game_test.dart
index e535174..946b9a0 100644
--- a/test/games/idioms/idioms_game_test.dart
+++ b/test/games/idioms/idioms_game_test.dart
@@ -1,85 +1,96 @@
 import 'package:flutter_test/flutter_test.dart';
 
 // ignore: avoid_relative_lib_imports
 import '../../../lib/games/idioms/idioms_content.dart';
 // ignore: avoid_relative_lib_imports
 import '../../../lib/games/idioms/idioms_game.dart';
 
 void main() {
   group('IdiomsGameState', () {
     final exercises = [
       _exercise(id: 'one', correctOptionIndex: 1),
       _exercise(id: 'two', correctOptionIndex: 2),
     ];
 
     test('starts at the first unanswered exercise', () {
       final state = IdiomsGameState(exercises: exercises);
 
       expect(state.currentIndex, 0);
       expect(state.correctCount, 0);
       expect(state.totalAnswered, 0);
       expect(state.selectedOptionIndices, [null, null]);
       expect(state.hasAnswered, isFalse);
       expect(state.isFinished, isFalse);
       expect(state.progress, 0);
     });
 
     test('records a correct answer', () {
       final state = IdiomsGameState(exercises: exercises).answer(1);
 
       expect(state.lastAnswerCorrect, isTrue);
       expect(state.correctCount, 1);
       expect(state.totalAnswered, 1);
       expect(state.results, [true, null]);
       expect(state.selectedOptionIndices, [1, null]);
     });
 
     test('records an incorrect answer', () {
       final state = IdiomsGameState(exercises: exercises).answer(0);
 
       expect(state.lastAnswerCorrect, isFalse);
       expect(state.correctCount, 0);
       expect(state.totalAnswered, 1);
       expect(state.results, [false, null]);
       expect(state.selectedOptionIndices, [0, null]);
     });
 
     test('ignores a second answer to the same exercise', () {
       final answered = IdiomsGameState(exercises: exercises).answer(0);
 
       expect(answered.answer(1), same(answered));
     });
 
     test('does not advance before an answer is selected', () {
       final state = IdiomsGameState(exercises: exercises);
 
       expect(state.next(), same(state));
     });
 
-    test('finishes after the last answered exercise', () {
+    test('progress counts only correct answers', () {
+      var state = IdiomsGameState(exercises: exercises);
+      state = state.answer(1).next();
+      state = state.answer(0).next();
+
+      expect(state.isFinished, isTrue);
+      expect(state.correctCount, 1);
+      expect(state.totalAnswered, 2);
+      expect(state.progress, 0.5);
+    });
+
+    test('progress is complete only after every correct answer', () {
       var state = IdiomsGameState(exercises: exercises);
       state = state.answer(1).next();
       state = state.answer(2).next();
 
       expect(state.isFinished, isTrue);
       expect(state.correctCount, 2);
       expect(state.totalAnswered, 2);
       expect(state.progress, 1);
       expect(state.selectedOptionIndices, [1, 2]);
     });
   });
 }
 
 IdiomExercise _exercise({required String id, required int correctOptionIndex}) {
   return IdiomExercise(
     id: id,
     expression: 'a pune umărul',
     meaning: 'a ajuta',
     example: 'Toți au pus umărul la proiect.',
     highlightedText: 'au pus umărul',
     options: const ['a pleca', 'a ajuta', 'a aștepta'],
     correctOptionIndex: correctOptionIndex,
     category: 'test',
     difficulty: 1,
   );
 }
diff --git a/test/games/spot/spot_game_test.dart b/test/games/spot/spot_game_test.dart
index 5124df7..3eaf101 100644
--- a/test/games/spot/spot_game_test.dart
+++ b/test/games/spot/spot_game_test.dart
@@ -61,167 +61,187 @@ void main() {
       expect(state.totalMistakesInCurrentText, 2);
       expect(state.allMistakesFoundInCurrentText, false);
       expect(state.textsCompleted, 0);
       expect(state.totalCorrectTaps, 0);
       expect(state.totalIncorrectTaps, 0);
       expect(state.accuracy, 1.0);
       expect(state.mode, SpotGameMode.normal);
     });
 
     test('tapWord finds a mistake', () {
       final state = createState();
       final outcome = state.tapWord(3);
 
       expect(outcome.result, SpotTapResult.found);
       expect(outcome.mistake, isNotNull);
       expect(outcome.mistake!.token, 'in');
       expect(outcome.state.mistakesFound, 1);
       expect(outcome.state.totalCorrectTaps, 1);
       expect(outcome.state.totalIncorrectTaps, 0);
       expect(outcome.state.allMistakesFoundInCurrentText, false);
     });
 
     test('tapWord on correct word records incorrect tap', () {
       final state = createState();
       final outcome = state.tapWord(0);
 
       expect(outcome.result, SpotTapResult.incorrect);
       expect(outcome.mistake, isNull);
       expect(outcome.state.mistakesFound, 0);
       expect(outcome.state.totalIncorrectTaps, 1);
       expect(outcome.state.shakingWordIndex, 0);
     });
 
     test('tapWord on already found mistake returns alreadyFound', () {
       final state = createState();
       final afterFirst = state.tapWord(3);
       final outcome = afterFirst.state.tapWord(3);
 
       expect(outcome.result, SpotTapResult.alreadyFound);
       expect(outcome.state.mistakesFound, 1);
     });
 
     test('clearShaker resets shakingWordIndex', () {
       final state = createState();
       final afterTap = state.tapWord(0);
       final cleared = afterTap.state.clearShaker();
 
       expect(cleared.shakingWordIndex, isNull);
       expect(afterTap.state.shakingWordIndex, 0);
     });
 
     test('isFoundMistakeWord returns true after finding', () {
       final state = createState();
       final afterFind = state.tapWord(3);
 
       expect(state.isFoundMistakeWord(3), false);
       expect(afterFind.state.isFoundMistakeWord(3), true);
       expect(afterFind.state.isFoundMistakeWord(0), false);
     });
 
     test('isUnfoundMistakeWord returns true for unfound mistakes', () {
       final state = createState();
 
       expect(state.isUnfoundMistakeWord(3), true);
       expect(state.isUnfoundMistakeWord(4), true);
       expect(state.isUnfoundMistakeWord(0), false);
 
       final afterFind = state.tapWord(3);
       expect(afterFind.state.isUnfoundMistakeWord(3), false);
       expect(afterFind.state.isUnfoundMistakeWord(4), true);
     });
 
     test('displayedWord always returns the original word', () {
       final state = createState();
 
       expect(state.displayedWord(3), 'in');
       final afterFind = state.tapWord(3);
       expect(afterFind.state.displayedWord(3), 'in');
     });
 
-    test('allMistakesFoundInCurrentText is true after all found', () {
+    test('a text is complete only when every mistake is found', () {
       final state = createState();
-      final state1 = state.tapWord(3).state;
-      final state2 = state1.tapWord(4).state;
+      final partiallyAnswered = state.tapWord(3).state;
+      final completelyAnswered = partiallyAnswered.tapWord(4).state;
+
+      expect(partiallyAnswered.isTextCompleted(0), isFalse);
+      expect(partiallyAnswered.allMistakesFoundInCurrentText, isFalse);
+      expect(completelyAnswered.mistakesFound, 2);
+      expect(completelyAnswered.isTextCompleted(0), isTrue);
+      expect(completelyAnswered.allMistakesFoundInCurrentText, isTrue);
+    });
+
+    test('notion results preserve each mistake answer', () {
+      final state = createState().tapWord(3).state;
+
+      expect(state.notionResults, {
+        'sp_in_%C3%AEn': true,
+        'sp_oras_ora%C8%99': false,
+        'sp_Mam_M-am': false,
+      });
+    });
+
+    test('empty state is not considered complete', () {
+      final state = SpotGameState(texts: const []);
 
-      expect(state2.mistakesFound, 2);
-      expect(state2.allMistakesFoundInCurrentText, true);
+      expect(state.isTextCompleted(0), isFalse);
+      expect(state.allMistakesFoundInCurrentText, isFalse);
     });
 
     test('nextText advances to next text and resets startTime', () {
       final state = createState();
       final allFound = state.tapWord(3).state.tapWord(4).state;
       final next = allFound.nextText();
 
       expect(next.currentTextIndex, 1);
       expect(next.mistakesFound, 0);
       expect(next.totalMistakesInCurrentText, 1);
     });
 
     test('nextText on last text finishes game', () {
       final state = createState();
       final text1Done = state.tapWord(3).state.tapWord(4).state;
       final text2 = text1Done.nextText();
       final text2Done = text2.tapWord(0).state;
       final finished = text2Done.nextText();
 
       expect(finished.isFinished, true);
       expect(finished.textsCompleted, 2);
     });
 
     group('deadline-based timer', () {
       test('remainingSeconds computed from startTime', () {
         final now = DateTime(2025, 1, 1, 12, 0, 0);
         final state = SpotGameState(texts: texts, startTime: now);
 
         final atStart = state.remainingSecondsAt(now);
         expect(atStart, 60);
 
         final after30 = state.remainingSecondsAt(
           now.add(const Duration(seconds: 30)),
         );
         expect(after30, 30);
 
         final after61 = state.remainingSecondsAt(
           now.add(const Duration(seconds: 61)),
         );
         expect(after61, 0);
       });
 
       test('isTimerExpired true when deadline passed', () {
         final now = DateTime(2025, 1, 1, 12, 0, 0);
         final state = SpotGameState(texts: texts, startTime: now);
 
         final expired = state.elapsedAt(
           now.add(const Duration(seconds: 61)),
         ).inSeconds >= 60;
         expect(expired, true);
       });
 
       test('remainingSeconds floors at zero', () {
         final now = DateTime(2025, 1, 1, 12, 0, 0);
         final state = SpotGameState(texts: texts, startTime: now);
 
         final after120 = state.remainingSecondsAt(
           now.add(const Duration(seconds: 120)),
         );
         expect(after120, 0);
       });
     });
 
     test('checkTimerExpiry advances on non-last text when expired', () {
       final now = DateTime(2025, 1, 1, 12, 0, 0);
       final state = SpotGameState(
         texts: texts,
         startTime: now.subtract(const Duration(seconds: 61)),
       );
 
       expect(state.isTimerExpired, isTrue);
       final advanced = state.checkTimerExpiry();
       expect(advanced.currentTextIndex, 1);
     });
 
     test('checkTimerExpiry finishes game on last text when expired', () {
       final now = DateTime(2025, 1, 1, 12, 0, 0);
       final state = SpotGameState(
         texts: texts,
         currentTextIndex: 1,
diff --git a/test/games/vocabulary/vocabulary_game_test.dart b/test/games/vocabulary/vocabulary_game_test.dart
index 5a3d915..f1b5f86 100644
--- a/test/games/vocabulary/vocabulary_game_test.dart
+++ b/test/games/vocabulary/vocabulary_game_test.dart
@@ -1,92 +1,103 @@
 import 'package:flutter_test/flutter_test.dart';
 
 // ignore: avoid_relative_lib_imports
 import '../../../lib/games/vocabulary/vocabulary_content.dart';
 // ignore: avoid_relative_lib_imports
 import '../../../lib/games/vocabulary/vocabulary_game.dart';
 
 void main() {
   group('VocabularyGameState', () {
     final exercises = [
       _exercise(id: 'one', correctOptionIndex: 1),
       _exercise(id: 'two', correctOptionIndex: 2),
     ];
 
     test('starts at the first unanswered exercise', () {
       final state = VocabularyGameState(exercises: exercises);
 
       expect(state.currentIndex, 0);
       expect(state.correctCount, 0);
       expect(state.totalAnswered, 0);
       expect(state.selectedOptionIndex, isNull);
       expect(state.selectedOptionIndices, [null, null]);
       expect(state.hasAnswered, isFalse);
       expect(state.isFinished, isFalse);
       expect(state.progress, 0);
     });
 
     test('records a correct answer', () {
       final state = VocabularyGameState(exercises: exercises).answer(1);
 
       expect(state.selectedOptionIndex, 1);
       expect(state.selectedOptionIndices, [1, null]);
       expect(state.lastAnswerCorrect, isTrue);
       expect(state.correctCount, 1);
       expect(state.totalAnswered, 1);
       expect(state.results, [true, null]);
     });
 
     test('records an incorrect answer', () {
       final state = VocabularyGameState(exercises: exercises).answer(0);
 
       expect(state.lastAnswerCorrect, isFalse);
       expect(state.correctCount, 0);
       expect(state.totalAnswered, 1);
       expect(state.results, [false, null]);
       expect(state.selectedOptionIndices, [0, null]);
     });
 
     test('ignores a second answer to the same exercise', () {
       final answered = VocabularyGameState(exercises: exercises).answer(0);
 
       expect(answered.answer(1), same(answered));
     });
 
     test('does not advance before an answer is selected', () {
       final state = VocabularyGameState(exercises: exercises);
 
       expect(state.next(), same(state));
     });
 
-    test('finishes after the last answered exercise', () {
+    test('progress counts only correct answers', () {
+      var state = VocabularyGameState(exercises: exercises);
+      state = state.answer(1).next();
+      state = state.answer(0).next();
+
+      expect(state.isFinished, isTrue);
+      expect(state.correctCount, 1);
+      expect(state.totalAnswered, 2);
+      expect(state.progress, 0.5);
+    });
+
+    test('progress is complete only after every correct answer', () {
       var state = VocabularyGameState(exercises: exercises);
       state = state.answer(1).next();
       state = state.answer(2).next();
 
       expect(state.isFinished, isTrue);
       expect(state.correctCount, 2);
       expect(state.totalAnswered, 2);
       expect(state.progress, 1);
       expect(state.selectedOptionIndices, [1, 2]);
     });
   });
 }
 
 VocabularyExercise _exercise({
   required String id,
   required int correctOptionIndex,
 }) {
   return VocabularyExercise(
     id: id,
     word: 'cuvânt $id',
     partOfSpeech: 'substantiv',
     definition: 'definiție',
     example: 'Acesta este un exemplu.',
     options: const ['prima', 'a doua', 'a treia'],
     correctOptionIndex: correctOptionIndex,
     explanation: 'Aceasta este explicația.',
     category: 'test',
     synonyms: const ['sinonim', 'echivalent'],
     difficulty: 1,
   );
 }
diff --git a/test/progress/lifecycle_persistence_test.dart b/test/progress/lifecycle_persistence_test.dart
new file mode 100644
index 0000000..a84dad0
--- /dev/null
+++ b/test/progress/lifecycle_persistence_test.dart
@@ -0,0 +1,100 @@
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+
+// ignore: avoid_relative_lib_imports
+import '../../lib/design/theme.dart';
+// ignore: avoid_relative_lib_imports
+import '../../lib/games/idioms/idioms_content.dart';
+// ignore: avoid_relative_lib_imports
+import '../../lib/games/idioms/idioms_screen.dart';
+// ignore: avoid_relative_lib_imports
+import '../../lib/progress/learning_item.dart';
+// ignore: avoid_relative_lib_imports
+import '../../lib/progress/user_progress.dart';
+
+void main() {
+  testWidgets('backgrounding a screen persists pending answers', (
+    tester,
+  ) async {
+    final storage = _LifecycleProgressStorage();
+    final repo = await ProgressRepository.load(storage: storage);
+
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: LexioTheme.light,
+        home: IdiomsScreen(
+          exercises: [_exercise()],
+          progressRepository: repo,
+        ),
+      ),
+    );
+
+    await tester.tap(find.text('a ajuta'));
+    await tester.pump();
+
+    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
+    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
+
+    final persisted = UserProgress.fromJson(storage.value!);
+    expect(
+      persisted.forGame('idioms').progressFor('a pune umărul').state,
+      LearningItemState.learning,
+    );
+
+    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
+  });
+
+  testWidgets('closing a screen persists pending answers', (tester) async {
+    final storage = _LifecycleProgressStorage();
+    final repo = await ProgressRepository.load(storage: storage);
+
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: LexioTheme.light,
+        home: IdiomsScreen(
+          exercises: [_exercise()],
+          progressRepository: repo,
+        ),
+      ),
+    );
+
+    await tester.tap(find.text('a ajuta'));
+    await tester.pump();
+
+    await tester.pumpWidget(const SizedBox.shrink());
+
+    final persisted = UserProgress.fromJson(storage.value!);
+    expect(
+      persisted.forGame('idioms').progressFor('a pune umărul').state,
+      LearningItemState.learning,
+    );
+  });
+}
+
+IdiomExercise _exercise() {
+  return IdiomExercise(
+    id: 'lifecycle_one',
+    expression: 'a pune umărul',
+    meaning: 'a contribui prin ajutor',
+    example: 'Toți au pus umărul la proiect.',
+    highlightedText: 'au pus umărul',
+    options: const ['a pleca', 'a ajuta', 'a aștepta'],
+    correctOptionIndex: 1,
+    category: 'cooperare',
+    difficulty: 1,
+  );
+}
+
+final class _LifecycleProgressStorage implements ProgressStorage {
+  String? value;
+  final List<String> writes = [];
+
+  @override
+  Future<String?> read() async => value;
+
+  @override
+  Future<void> write(String updated) async {
+    writes.add(updated);
+    value = updated;
+  }
+}
diff --git a/test/progress/progress_repository_test.dart b/test/progress/progress_repository_test.dart
new file mode 100644
index 0000000..11d94b0
--- /dev/null
+++ b/test/progress/progress_repository_test.dart
@@ -0,0 +1,200 @@
+import 'dart:async';
+
+import 'package:flutter_test/flutter_test.dart';
+
+// ignore: avoid_relative_lib_imports
+import '../../lib/progress/learning_item.dart';
+// ignore: avoid_relative_lib_imports
+import '../../lib/progress/user_progress.dart';
+
+void main() {
+  group('ProgressRepository', () {
+    test('loads persisted progress from storage', () async {
+      final storage = _MemoryProgressStorage();
+      await storage.write(
+        const UserProgress().recordAnswer(
+          gameId: 'grammar',
+          notionId: 'n_loaded',
+          isCorrect: true,
+          today: 100,
+        ).toJson(),
+      );
+
+      final repo = await ProgressRepository.load(storage: storage);
+
+      final item = repo.forGame('grammar').progressFor('n_loaded');
+      expect(item.state, LearningItemState.learning);
+      expect(item.nextReviewDay, 101);
+    });
+
+    test('flush persists an ignored recordAnswer future', () async {
+      final storage = _BlockingProgressStorage();
+      final repo = await ProgressRepository.load(storage: storage);
+
+      repo.recordAnswer(
+        gameId: 'grammar',
+        notionId: 'n_flushed',
+        isCorrect: true,
+      );
+
+      final flush = repo.flush();
+      var completed = false;
+      flush.whenComplete(() => completed = true);
+      await Future<void>.delayed(Duration.zero);
+      expect(completed, isFalse);
+
+      storage.pendingWrites.single.complete();
+      await flush;
+
+      final persisted = UserProgress.fromJson(storage.value!);
+      expect(
+        persisted.forGame('grammar').progressFor('n_flushed').state,
+        LearningItemState.learning,
+      );
+    });
+
+    test('failed write is swallowed and a later retry persists', () async {
+      final storage = _MemoryProgressStorage()..failuresRemaining = 1;
+      final repo = await ProgressRepository.load(storage: storage);
+
+      await repo.recordAnswer(
+        gameId: 'grammar',
+        notionId: 'n_failed',
+        isCorrect: true,
+      );
+
+      await repo.recordAnswer(
+        gameId: 'grammar',
+        notionId: 'n_failed',
+        isCorrect: true,
+      );
+      await repo.flush();
+
+      final persisted = UserProgress.fromJson(storage.value!);
+      expect(
+        persisted.forGame('grammar').progressFor('n_failed').state,
+        LearningItemState.learning,
+      );
+    });
+
+    test('rapid answer sequence persists every answer in order', () async {
+      final storage = _MemoryProgressStorage();
+      final repo = await ProgressRepository.load(storage: storage);
+
+      for (var i = 0; i < 5; i++) {
+        repo.recordAnswer(
+          gameId: 'grammar',
+          notionId: 'n_$i',
+          isCorrect: true,
+        );
+      }
+      await repo.flush();
+
+      expect(storage.writes, hasLength(5));
+      for (var i = 0; i < 5; i++) {
+        final snapshot = UserProgress.fromJson(storage.writes[i]);
+        expect(snapshot.forGame('grammar').items, hasLength(i + 1));
+      }
+    });
+
+    test('recordAnswers persists multiple notions in one flush', () async {
+      final storage = _MemoryProgressStorage();
+      final repo = await ProgressRepository.load(storage: storage);
+
+      repo.recordAnswers(gameId: 'spot', notionResults: {
+        'n_a': true,
+        'n_b': false,
+      });
+      await repo.flush();
+
+      final persisted = UserProgress.fromJson(storage.value!);
+      final spot = persisted.forGame('spot');
+      expect(spot.items, hasLength(2));
+      expect(spot.progressFor('n_a').state, LearningItemState.learning);
+      expect(spot.progressFor('n_b').state, LearningItemState.learning);
+    });
+
+    test('load recovers from a failing storage read', () async {
+      final repo = await ProgressRepository.load(
+        storage: _FailingReadProgressStorage(),
+      );
+
+      expect(repo.forGame('grammar').items, isEmpty);
+      await repo.recordAnswer(
+        gameId: 'grammar',
+        notionId: 'n_memory_only',
+        isCorrect: true,
+      );
+      await repo.flush();
+    });
+
+    test('writes are serialized one at a time', () async {
+      final storage = _BlockingProgressStorage();
+      final repo = await ProgressRepository.load(storage: storage);
+
+      repo.recordAnswer(
+        gameId: 'grammar',
+        notionId: 'n_first',
+        isCorrect: true,
+      );
+      repo.recordAnswer(
+        gameId: 'grammar',
+        notionId: 'n_second',
+        isCorrect: true,
+      );
+
+      await Future<void>.delayed(Duration.zero);
+      expect(storage.pendingWrites, hasLength(1));
+
+      storage.pendingWrites.first.complete();
+      await Future<void>.delayed(Duration.zero);
+      expect(storage.pendingWrites, hasLength(2));
+
+      storage.pendingWrites.last.complete();
+      await repo.flush();
+    });
+  });
+}
+
+final class _MemoryProgressStorage implements ProgressStorage {
+  String? value;
+  int failuresRemaining = 0;
+  final List<String> writes = [];
+
+  @override
+  Future<String?> read() async => value;
+
+  @override
+  Future<void> write(String updated) async {
+    if (failuresRemaining > 0) {
+      failuresRemaining--;
+      throw Exception('write failed');
+    }
+    writes.add(updated);
+    value = updated;
+  }
+}
+
+final class _BlockingProgressStorage implements ProgressStorage {
+  String? value;
+  final List<Completer<void>> pendingWrites = [];
+
+  @override
+  Future<String?> read() async => value;
+
+  @override
+  Future<void> write(String updated) {
+    value = updated;
+    final completer = Completer<void>();
+    pendingWrites.add(completer);
+    return completer.future;
+  }
+}
+
+final class _FailingReadProgressStorage implements ProgressStorage {
+  @override
+  Future<String?> read() async => throw Exception('read failed');
+
+  @override
+  Future<void> write(String updated) async {}
+}
