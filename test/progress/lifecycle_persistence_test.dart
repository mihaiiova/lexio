import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/idioms/idioms_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/idioms/idioms_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/learning_item.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/user_progress.dart';

void main() {
  testWidgets('backgrounding a screen persists pending answers', (
    tester,
  ) async {
    final storage = _LifecycleProgressStorage();
    final repo = await ProgressRepository.load(storage: storage);

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: IdiomsScreen(
          exercises: [_exercise()],
          progressRepository: repo,
        ),
      ),
    );

    await tester.tap(find.text('a ajuta'));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    final persisted = UserProgress.fromJson(storage.value!);
    expect(
      persisted.forGame('idioms').progressFor('a pune umărul').state,
      LearningItemState.learning,
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('closing a screen persists pending answers', (tester) async {
    final storage = _LifecycleProgressStorage();
    final repo = await ProgressRepository.load(storage: storage);

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: IdiomsScreen(
          exercises: [_exercise()],
          progressRepository: repo,
        ),
      ),
    );

    await tester.tap(find.text('a ajuta'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());

    final persisted = UserProgress.fromJson(storage.value!);
    expect(
      persisted.forGame('idioms').progressFor('a pune umărul').state,
      LearningItemState.learning,
    );
  });
}

IdiomExercise _exercise() {
  return IdiomExercise(
    id: 'lifecycle_one',
    expression: 'a pune umărul',
    meaning: 'a contribui prin ajutor',
    example: 'Toți au pus umărul la proiect.',
    highlightedText: 'au pus umărul',
    options: const ['a pleca', 'a ajuta', 'a aștepta'],
    correctOptionIndex: 1,
    category: 'cooperare',
    difficulty: 1,
  );
}

final class _LifecycleProgressStorage implements ProgressStorage {
  String? value;
  final List<String> writes = [];

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String updated) async {
    writes.add(updated);
    value = updated;
  }
}
