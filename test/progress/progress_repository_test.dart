import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/progress/learning_item.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/user_progress.dart';

void main() {
  group('ProgressRepository', () {
    test('loads persisted progress from storage', () async {
      final storage = _MemoryProgressStorage();
      await storage.write(
        const UserProgress().recordAnswer(
          gameId: 'grammar',
          notionId: 'n_loaded',
          isCorrect: true,
          today: 100,
        ).toJson(),
      );

      final repo = await ProgressRepository.load(storage: storage);

      final item = repo.forGame('grammar').progressFor('n_loaded');
      expect(item.state, LearningItemState.learning);
      expect(item.nextReviewDay, 101);
    });
  });
}

final class _MemoryProgressStorage implements ProgressStorage {
  _MemoryProgressStorage([this.value]);

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
