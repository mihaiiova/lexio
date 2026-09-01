import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/home/home_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/learning_item.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/user_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows a progress bar per game without a count label', (
    tester,
  ) async {
    final progress = UserProgress(
      games: {
        'vocabulary': GameProgress(
          items: {
            'w1': const LearningItem(
              notionId: 'w1',
              state: LearningItemState.mastered,
              step: LearningItem.mastered60d,
              nextReviewDay: 200,
              lastAnsweredDay: 140,
            ),
            'w2': const LearningItem(
              notionId: 'w2',
              state: LearningItemState.mastered,
              step: LearningItem.mastered60d,
              nextReviewDay: 200,
              lastAnsweredDay: 140,
            ),
          },
        ),
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          progressStorage: _MemoryProgressStorage(progress.toJson()),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    final indicators = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList();

    expect(indicators, hasLength(4));
    expect(indicators[0].value, 0);
    expect(indicators[1].value, closeTo(0.02, 0.0001));
    expect(indicators[2].value, 0);
    expect(indicators[3].value, 0);
    expect(find.textContaining('din'), findsNothing);
  });
}

final class _MemoryProgressStorage implements ProgressStorage {
  final String? value;

  const _MemoryProgressStorage(this.value);

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {}
}
