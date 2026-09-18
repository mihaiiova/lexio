import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/progress/learning_item.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/user_progress.dart';
import 'dart:async';

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

    test('flush persists an ignored recordAnswer future', () async {
      final storage = _BlockingProgressStorage();
      final repo = await ProgressRepository.load(storage: storage);

      repo.recordAnswer(
        gameId: 'grammar',
        notionId: 'n_flushed',
        isCorrect: true,
      );

      final flush = repo.flush();
      var completed = false;
      flush.whenComplete(() => completed = true);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      storage.pendingWrites.single.complete();
      await flush;

      final persisted = UserProgress.fromJson(storage.value!);
      expect(
        persisted.forGame('grammar').progressFor('n_flushed').state,
        LearningItemState.learning,
      );
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

final class _BlockingProgressStorage implements ProgressStorage {
  String? value;
  final List<Completer<void>> pendingWrites = [];

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String updated) {
    value = updated;
    final completer = Completer<void>();
    pendingWrites.add(completer);
    return completer.future;
  }
}
