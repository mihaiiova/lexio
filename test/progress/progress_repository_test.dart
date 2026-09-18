import 'dart:async';

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

    test('failed write is swallowed and a later retry persists', () async {
      final storage = _MemoryProgressStorage()..failuresRemaining = 1;
      final repo = await ProgressRepository.load(storage: storage);

      await repo.recordAnswer(
        gameId: 'grammar',
        notionId: 'n_failed',
        isCorrect: true,
      );

      await repo.recordAnswer(
        gameId: 'grammar',
        notionId: 'n_failed',
        isCorrect: true,
      );
      await repo.flush();

      final persisted = UserProgress.fromJson(storage.value!);
      expect(
        persisted.forGame('grammar').progressFor('n_failed').state,
        LearningItemState.learning,
      );
    });

    test('rapid answer sequence persists every answer in order', () async {
      final storage = _MemoryProgressStorage();
      final repo = await ProgressRepository.load(storage: storage);

      for (var i = 0; i < 5; i++) {
        repo.recordAnswer(
          gameId: 'grammar',
          notionId: 'n_$i',
          isCorrect: true,
        );
      }
      await repo.flush();

      expect(storage.writes, hasLength(5));
      for (var i = 0; i < 5; i++) {
        final snapshot = UserProgress.fromJson(storage.writes[i]);
        expect(snapshot.forGame('grammar').items, hasLength(i + 1));
      }
    });

    test('recordAnswers persists multiple notions in one flush', () async {
      final storage = _MemoryProgressStorage();
      final repo = await ProgressRepository.load(storage: storage);

      repo.recordAnswers(gameId: 'spot', notionResults: {
        'n_a': true,
        'n_b': false,
      });
      await repo.flush();

      final persisted = UserProgress.fromJson(storage.value!);
      final spot = persisted.forGame('spot');
      expect(spot.items, hasLength(2));
      expect(spot.progressFor('n_a').state, LearningItemState.learning);
      expect(spot.progressFor('n_b').state, LearningItemState.learning);
    });

    test('load recovers from a failing storage read', () async {
      final repo = await ProgressRepository.load(
        storage: _FailingReadProgressStorage(),
      );

      expect(repo.forGame('grammar').items, isEmpty);
      await repo.recordAnswer(
        gameId: 'grammar',
        notionId: 'n_memory_only',
        isCorrect: true,
      );
      await repo.flush();
    });

    test('writes are serialized one at a time', () async {
      final storage = _BlockingProgressStorage();
      final repo = await ProgressRepository.load(storage: storage);

      repo.recordAnswer(
        gameId: 'grammar',
        notionId: 'n_first',
        isCorrect: true,
      );
      repo.recordAnswer(
        gameId: 'grammar',
        notionId: 'n_second',
        isCorrect: true,
      );

      await Future<void>.delayed(Duration.zero);
      expect(storage.pendingWrites, hasLength(1));

      storage.pendingWrites.first.complete();
      await Future<void>.delayed(Duration.zero);
      expect(storage.pendingWrites, hasLength(2));

      storage.pendingWrites.last.complete();
      await repo.flush();
    });
  });
}

final class _MemoryProgressStorage implements ProgressStorage {
  String? value;
  int failuresRemaining = 0;
  final List<String> writes = [];

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String updated) async {
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw Exception('write failed');
    }
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

final class _FailingReadProgressStorage implements ProgressStorage {
  @override
  Future<String?> read() async => throw Exception('read failed');

  @override
  Future<void> write(String updated) async {}
}
