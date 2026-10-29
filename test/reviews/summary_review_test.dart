import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/design/colors.dart';
import 'package:lexio/design/components/lexio_game_summary.dart';
import 'package:lexio/reviews/app_review_service.dart';

class _RecordingReviews extends AppReviewService {
  var completedRounds = 0;
  bool Function()? canPrompt;

  @override
  Future<void> onRoundCompleted({required bool Function() canPrompt}) async {
    completedRounds++;
    this.canPrompt = canPrompt;
  }
}

void main() {
  testWidgets('summary records one completion, not one per rebuild', (
    tester,
  ) async {
    final service = _RecordingReviews();
    Widget summary() => MaterialApp(
      home: Scaffold(
        body: LexioGameSummary(
          accentColor: LexioColors.primary,
          correctCount: 0,
          totalCount: 5,
          reviewItems: const [],
          onPlayAgain: () {},
          onBack: () {},
          reviewService: service,
        ),
      ),
    );
    await tester.pumpWidget(summary());
    expect(service.completedRounds, 1);
    await tester.pumpWidget(summary());
    expect(service.completedRounds, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(service.canPrompt!(), isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(service.canPrompt!(), isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(service.canPrompt!(), isFalse);
  });
}
