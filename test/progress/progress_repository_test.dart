import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/progress/learning_item.dart';
import 'package:lexio/progress/user_progress.dart';

void main() {
  group('ProgressRepository persistence', () {
    test('writes the latest snapshot after rapid sequential answers', () async {
      final storage = _ControlledProgressStorage();
      final repository = ProgressRepository(storage: storage);

      final first = repository.recordAnswer(
        gameId: 'vocabulary',
        notionId: 'first',
        isCorrect: true,
      );
      final second = repository.recordAnswer(
        gameId: 'vocabulary',
        notionId: 'second',
        isCorrect: false,
      );

      await _flushMicrotasks();
      expect(storage.pendingWrites, hasLength(1));

      storage.completeNextWrite();
      await _flushMicrotasks();
      expect(storage.pendingWrites, hasLength(2));

      storage.completeNextWrite();
      await Future.wait([first, second]);

      final saved = UserProgress.fromJson(storage.value!);
      expect(
        saved.forGame('vocabulary').items.keys,
        containsAll(['first', 'second']),
      );
    });

    test('keeps in-memory progress when a storage write fails', () async {
      final repository = ProgressRepository(storage: _FailingProgressStorage());

      await repository.recordAnswer(
        gameId: 'grammar',
        notionId: 'agreement',
        isCorrect: true,
      );

      expect(
        repository.forGame('grammar').progressFor('agreement').state,
        LearningItemState.learning,
      );
    });

    test('persists a newer snapshot after an earlier write fails', () async {
      final storage = _FailFirstProgressStorage();
      final repository = ProgressRepository(storage: storage);

      await repository.recordAnswer(
        gameId: 'spot',
        notionId: 'first',
        isCorrect: true,
      );
      await repository.recordAnswer(
        gameId: 'spot',
        notionId: 'second',
        isCorrect: false,
      );

      final saved = UserProgress.fromJson(storage.value!);
      expect(
        saved.forGame('spot').items.keys,
        containsAll(['first', 'second']),
      );
    });

    test('loads a compatible stored snapshot', () async {
      final stored = const UserProgress().recordAnswer(
        gameId: 'idioms',
        notionId: 'idiom_1',
        isCorrect: true,
        today: 100,
      );
      final repository = await ProgressRepository.load(
        storage: _StoredProgressStorage(stored.toJson()),
      );

      expect(
        repository.forGame('idioms').progressFor('idiom_1').nextReviewDay,
        101,
      );
    });
  });
}

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

final class _ControlledProgressStorage implements ProgressStorage {
  final List<_PendingWrite> pendingWrites = [];
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) {
    final pending = _PendingWrite(value);
    pendingWrites.add(pending);
    return pending.completer.future.then((_) => this.value = value);
  }

  void completeNextWrite() => pendingWrites
      .firstWhere((pending) => !pending.completer.isCompleted)
      .completer
      .complete();
}

final class _FailingProgressStorage implements ProgressStorage {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) =>
      Future<void>.error(StateError('Storage unavailable'));
}

final class _FailFirstProgressStorage implements ProgressStorage {
  int _writeCount = 0;
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) {
    if (_writeCount++ == 0) {
      return Future<void>.error(StateError('Storage unavailable'));
    }
    this.value = value;
    return Future<void>.value();
  }
}

final class _StoredProgressStorage implements ProgressStorage {
  final String storedValue;

  const _StoredProgressStorage(this.storedValue);

  @override
  Future<String?> read(String key) async => storedValue;

  @override
  Future<void> write(String key, String value) async {}
}

final class _PendingWrite {
  final String value;
  final Completer<void> completer = Completer<void>();

  _PendingWrite(this.value);
}
