import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/design/colors.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/design/components/lexio_game_card.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/home/home_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/user_progress.dart';

void main() {
  testWidgets('renders game entries with an injected progress repository', (
    tester,
  ) async {
    final repo = await ProgressRepository.load(storage: _MemoryStorage());

    await tester.pumpWidget(
      MaterialApp(theme: LexioTheme.light, home: HomeScreen(progressRepository: repo)),
    );

    expect(find.byType(LexioGameCard), findsNWidgets(4));
    expect(find.text('Corect sau greșit?'), findsOneWidget);
    expect(find.text('Ce înseamnă?'), findsOneWidget);
    expect(find.text('Vorba vine'), findsOneWidget);
    expect(find.text('Găsește greșeala'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, LexioColors.backgroundSubtle);
  });
}

final class _MemoryStorage implements ProgressStorage {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async {
    _value = value;
  }
}
