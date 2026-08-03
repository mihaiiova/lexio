enum LearningItemState { newItem, learning, consolidating, mastered }

final class LearningItem {
  final String notionId;
  final LearningItemState state;
  final int step;
  final int nextReviewDay;
  final int lastAnsweredDay;

  static const initialStep = -1;
  static const recoveryStep = -2;
  static const consolidating3d = 0;
  static const consolidating7d = 1;
  static const consolidating21d = 2;
  static const mastered60d = 60;
  static const mastered120d = 120;

  const LearningItem({
    required this.notionId,
    required this.state,
    required this.step,
    required this.nextReviewDay,
    required this.lastAnsweredDay,
  });

  const LearningItem.newItem({required this.notionId})
    : state = LearningItemState.newItem,
      step = initialStep,
      nextReviewDay = 0,
      lastAnsweredDay = 0;

  bool isOverdue(int today) =>
      state != LearningItemState.newItem && nextReviewDay <= today;

  bool isEligibleForReview(int today) =>
      state == LearningItemState.newItem || nextReviewDay <= today;

  LearningItem recordAnswer({
    required bool isCorrect,
    required int today,
  }) {
    if (state == LearningItemState.newItem) {
      return LearningItem(
        notionId: notionId,
        state: LearningItemState.learning,
        step: initialStep,
        nextReviewDay: today + 1,
        lastAnsweredDay: today,
      );
    }

    if (state == LearningItemState.learning) {
      if (isCorrect && nextReviewDay <= today) {
        return LearningItem(
          notionId: notionId,
          state: LearningItemState.consolidating,
          step: consolidating3d,
          nextReviewDay: today + 3,
          lastAnsweredDay: today,
        );
      }
      if (!isCorrect) {
        return LearningItem(
          notionId: notionId,
          state: LearningItemState.learning,
          step: initialStep,
          nextReviewDay: today + 1,
          lastAnsweredDay: today,
        );
      }
      return this;
    }

    if (state == LearningItemState.consolidating) {
      if (!isCorrect) {
        return LearningItem(
          notionId: notionId,
          state: LearningItemState.learning,
          step: initialStep,
          nextReviewDay: today + 1,
          lastAnsweredDay: today,
        );
      }
      if (nextReviewDay <= today) {
        return switch (step) {
          consolidating3d => LearningItem(
            notionId: notionId,
            state: LearningItemState.consolidating,
            step: consolidating7d,
            nextReviewDay: today + 7,
            lastAnsweredDay: today,
          ),
          consolidating7d => LearningItem(
            notionId: notionId,
            state: LearningItemState.consolidating,
            step: consolidating21d,
            nextReviewDay: today + 21,
            lastAnsweredDay: today,
          ),
          consolidating21d => LearningItem(
            notionId: notionId,
            state: LearningItemState.mastered,
            step: mastered60d,
            nextReviewDay: today + 60,
            lastAnsweredDay: today,
          ),
          recoveryStep => LearningItem(
            notionId: notionId,
            state: LearningItemState.consolidating,
            step: consolidating3d,
            nextReviewDay: today + 3,
            lastAnsweredDay: today,
          ),
          _ => this,
        };
      }
      return this;
    }

    if (state == LearningItemState.mastered) {
      if (!isCorrect) {
        return LearningItem(
          notionId: notionId,
          state: LearningItemState.consolidating,
          step: recoveryStep,
          nextReviewDay: today + 1,
          lastAnsweredDay: today,
        );
      }
      if (nextReviewDay <= today) {
        final nextInterval =
            step == mastered60d ? mastered120d : mastered120d;
        return LearningItem(
          notionId: notionId,
          state: LearningItemState.mastered,
          step: nextInterval,
          nextReviewDay: today + nextInterval,
          lastAnsweredDay: today,
        );
      }
      return this;
    }

    return this;
  }

  Map<String, dynamic> toJson() => {
    'notionId': notionId,
    'state': state.index,
    'step': step,
    'nextReviewDay': nextReviewDay,
    'lastAnsweredDay': lastAnsweredDay,
  };

  factory LearningItem.fromJson(Map<String, dynamic> json) {
    return LearningItem(
      notionId: json['notionId'] as String,
      state: LearningItemState.values[json['state'] as int],
      step: json['step'] as int? ?? initialStep,
      nextReviewDay: json['nextReviewDay'] as int? ?? 0,
      lastAnsweredDay: json['lastAnsweredDay'] as int? ?? 0,
    );
  }
}
