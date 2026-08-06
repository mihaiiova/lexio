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
  int get mistakesFound => foundMistakeIndices[currentTextIndex].length;
  int get totalMistakesInCurrentText => currentText.mistakes.length;
  bool get allMistakesFoundInCurrentText =>
      mistakesFound == totalMistakesInCurrentText;
  bool get isLastText => currentTextIndex >= texts.length - 1;

  int get textsCompleted {
    int count = 0;
    for (int i = 0; i < texts.length; i++) {
      if (foundMistakeIndices[i].length == texts[i].mistakes.length) {
        count++;
      }
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
    }

    final mistakeIndex = _findMistakeIndex(wordIndex);

    if (mistakeIndex != null) {
      final newFound = List<Set<int>>.from(
        foundMistakeIndices.map((s) => Set<int>.from(s)),
      );
      newFound[currentTextIndex] = Set<int>.from(newFound[currentTextIndex])
        ..add(mistakeIndex);

      return SpotTapOutcome(
        state: _copyWith(foundMistakeIndices: newFound),
        result: SpotTapResult.found,
        mistake: currentText.mistakes[mistakeIndex],
      );
    }

    final newIncorrect = List<Set<int>>.from(
      incorrectTapWordIndices.map((s) => Set<int>.from(s)),
    );
    newIncorrect[currentTextIndex] = Set<int>.from(
      newIncorrect[currentTextIndex],
    )..add(wordIndex);

    return SpotTapOutcome(
      state: _copyWith(
        incorrectTapWordIndices: newIncorrect,
        shakingWordIndex: wordIndex,
      ),
      result: SpotTapResult.incorrect,
    );
  }

  SpotGameState clearShaker() {
    if (shakingWordIndex == null) return this;
    return _copyWith(shakingWordIndex: null, clearShaker: true);
  }

  SpotGameState nextText() {
    if (isLastText) {
      return _copyWith(
        isFinished: true,
        isChecking: false,
        frozenRemainingSeconds: remainingSeconds,
      );
    }
    return _copyWith(
      currentTextIndex: currentTextIndex + 1,
      isChecking: false,
      startTime: DateTime.now(),
    );
  }

  SpotGameState checkTimerExpiry() {
    if (isFinished || !isTimerExpired) return this;
    if (isLastText) {
      return _copyWith(
        isFinished: true,
        frozenRemainingSeconds: 0,
      );
    }
    return _copyWith(
      currentTextIndex: currentTextIndex + 1,
      startTime: DateTime.now(),
    );
  }

  SpotGameState checkAnswers() => _copyWith(isChecking: true);

  SpotGameState _copyWith({
    List<Set<int>>? foundMistakeIndices,
    List<Set<int>>? incorrectTapWordIndices,
    int? currentTextIndex,
    bool? isFinished,
    bool? isChecking,
    DateTime? startTime,
    int? shakingWordIndex,
    bool clearShaker = false,
    int? frozenRemainingSeconds,
  }) {
    return SpotGameState(
      texts: texts,
      currentTextIndex: currentTextIndex ?? this.currentTextIndex,
      foundMistakeIndices: foundMistakeIndices ?? this.foundMistakeIndices,
      incorrectTapWordIndices:
          incorrectTapWordIndices ?? this.incorrectTapWordIndices,
      mode: mode,
      startTime: startTime ?? this.startTime,
      isFinished: isFinished ?? this.isFinished,
      isChecking: isChecking ?? this.isChecking,
      shakingWordIndex: clearShaker
          ? null
          : (shakingWordIndex ?? this.shakingWordIndex),
      frozenRemainingSeconds:
          frozenRemainingSeconds ?? _frozenRemainingSeconds,
    );
  }

  int? _findMistakeIndex(int wordIndex) {
    final found = foundMistakeIndices[currentTextIndex];
    for (int i = 0; i < currentText.mistakes.length; i++) {
      if (currentText.mistakes[i].containsWordIndex(wordIndex) &&
          !found.contains(i)) {
        return i;
      }
    }
    return null;
  }
}
