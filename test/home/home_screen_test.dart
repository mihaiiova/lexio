import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/design/colors.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/design/components/lexio_game_card.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/home/home_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/learning_item.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/user_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders one progress card per game on a light-gray background', (
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

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, LexioColors.backgroundSubtle);

    expect(find.byType(Divider), findsNothing);

    final cards = tester
        .widgetList<LexioGameCard>(find.byType(LexioGameCard))
        .toList();
    expect(cards, hasLength(4));

    expect(cards[0].title, 'Corect sau greșit?');
    expect(cards[0].accentColor, LexioColors.primary);
    expect(cards[0].mutedColor, LexioColors.primaryMuted);
    expect(cards[0].discovered, 0);
    expect(cards[0].total, greaterThan(0));

    expect(cards[1].title, 'Ce înseamnă?');
    expect(cards[1].accentColor, LexioColors.secondary);
    expect(cards[1].mutedColor, LexioColors.secondaryMuted);
    expect(cards[1].discovered, 2);
    expect(cards[1].total, 100);

    expect(cards[2].title, 'Vorba vine');
    expect(cards[2].accentColor, LexioColors.teal);
    expect(cards[2].mutedColor, LexioColors.tealMuted);
    expect(cards[2].discovered, 0);
    expect(cards[2].total, greaterThan(0));

    expect(cards[3].title, 'Găsește greșeala');
    expect(cards[3].accentColor, LexioColors.accent);
    expect(cards[3].mutedColor, LexioColors.accentMuted);
    expect(cards[3].discovered, 0);
    expect(cards[3].total, greaterThan(0));

    expect(find.text('2/100'), findsOneWidget);
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
