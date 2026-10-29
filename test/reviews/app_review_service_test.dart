import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexio/reviews/app_review_service.dart';

void main() {
  late DateTime now;
  late int requests;
  late int storeOpens;
  late bool available;
  late AppReviewService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime.utc(2026, 1, 1);
    requests = 0;
    storeOpens = 0;
    available = true;
    service = AppReviewService(
      supported: true,
      now: () => now,
      isAvailable: () async => available,
      requestReview: () async {
        requests++;
      },
      openStoreListing: () async {
        storeOpens++;
      },
    );
  });

  Future<void> complete([int count = 1]) async {
    for (var i = 0; i < count; i++) {
      await service.onRoundCompleted(canPrompt: () => true);
    }
  }

  test('does not prompt on first launch or before seven days', () async {
    await service.initialize();
    await complete(10);
    now = now.add(const Duration(days: 6));
    await complete();
    expect(requests, 0);
    now = now.add(const Duration(days: 1));
    await complete();
    expect(requests, 1);
  });

  test('requires five completed rounds independently of score', () async {
    await service.initialize();
    now = now.add(const Duration(days: 7));
    await complete(4);
    expect(requests, 0);
    await complete();
    expect(requests, 1);
  });

  test('cooldown persists across service instances', () async {
    await service.initialize();
    now = now.add(const Duration(days: 7));
    await complete(5);
    service = AppReviewService(
      supported: true,
      now: () => now,
      isAvailable: () async => true,
      requestReview: () async {
        requests++;
      },
    );
    now = now.add(const Duration(days: 119));
    await complete();
    expect(requests, 1);
    now = now.add(const Duration(days: 1));
    await complete();
    expect(requests, 2);
  });

  test(
    'unavailable stores and inactive screens do not consume cooldown',
    () async {
      await service.initialize();
      now = now.add(const Duration(days: 7));
      available = false;
      await complete(5);
      expect(requests, 0);
      available = true;
      await service.onRoundCompleted(canPrompt: () => false);
      expect(requests, 0);
      await complete();
      expect(requests, 1);
    },
  );

  test(
    'native errors are swallowed and do not trigger a store fallback',
    () async {
      await service.initialize();
      now = now.add(const Duration(days: 7));
      service = AppReviewService(
        supported: true,
        now: () => now,
        isAvailable: () async => true,
        requestReview: () async {
          requests++;
          throw StateError('store');
        },
        openStoreListing: () async {
          storeOpens++;
        },
      );
      await complete(6);
      expect(requests, 1);
      expect(storeOpens, 0);
    },
  );

  test('explicit store action is independent of native quota', () async {
    available = false;
    expect(await service.openStore(), isTrue);
    expect(storeOpens, 1);
    expect(requests, 0);
  });

  test('unsupported platforms never call native APIs', () async {
    service = AppReviewService(
      supported: false,
      requestReview: () async {
        requests++;
      },
    );
    await complete(10);
    expect(await service.openStore(), isFalse);
    expect(requests, 0);
  });

  test('iOS store link requires a numeric Apple app ID', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(AppReviewService(appStoreId: '').canOpenStore, isFalse);
    expect(
      AppReviewService(appStoreId: 'com.example.app').canOpenStore,
      isFalse,
    );
    expect(AppReviewService(appStoreId: '123456789').canOpenStore, isTrue);
  });

  test('storage failure never interrupts a round', () async {
    service = AppReviewService(
      supported: true,
      preferences: () async => throw StateError('storage'),
    );
    await service.initialize();
    await service.onRoundCompleted(canPrompt: () => true);
  });
}
