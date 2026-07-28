import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/content/hyphenation_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/spot/spot_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('spot corpus satisfies content constraints', () async {
    final texts = await SpotContent.load();
    final hyphenationPairs = await HyphenationContent.load();
    final commonJson = await rootBundle.loadString(
      'data/common_error_pairs.json',
    );
    final commonPairCount = (json.decode(commonJson) as List<dynamic>).length;
    final ids = texts.map((text) => text.id).toSet();
    final hyphenationPairIds = hyphenationPairs.map((pair) => pair.id).toSet();
    final usedCommonPairIndices = <int>{};
    final usedHyphenationPairIds = <String>{};
    final visiblePairCounts = <String, int>{};

    expect(texts, hasLength(60));
    expect(ids, hasLength(texts.length));

    for (final text in texts) {
      expect(text.type, isNot('whatsapp'), reason: text.id);
      expect(text.mistakes.length, inInclusiveRange(3, 5), reason: text.id);

      final mistakeRanges = <(int, int)>[];
      for (final mistake in text.mistakes) {
        final rangeEnd = mistake.wordIndex + mistake.wordCount;
        expect(
          mistake.wordIndex,
          inInclusiveRange(0, text.words.length - 1),
          reason: text.id,
        );
        expect(rangeEnd, lessThanOrEqualTo(text.words.length), reason: text.id);
        expect(
          text.words.sublist(mistake.wordIndex, rangeEnd).join(' '),
          mistake.token,
          reason: '${text.id} at index ${mistake.wordIndex}',
        );

        for (final (start, end) in mistakeRanges) {
          expect(
            mistake.wordIndex >= end || rangeEnd <= start,
            isTrue,
            reason: '${text.id} has overlapping mistake ranges',
          );
        }
        mistakeRanges.add((mistake.wordIndex, rangeEnd));

        final commonPairIndex = mistake.commonErrorPairIndex;
        final hyphenationPairId = mistake.hyphenationPairId;
        expect(
          (commonPairIndex == null) != (hyphenationPairId == null),
          isTrue,
          reason: '${text.id} must reference exactly one source',
        );
        if (commonPairIndex != null) {
          expect(
            commonPairIndex,
            inInclusiveRange(0, commonPairCount - 1),
            reason: text.id,
          );
          usedCommonPairIndices.add(commonPairIndex);
        }
        if (hyphenationPairId != null) {
          expect(
            hyphenationPairIds,
            contains(hyphenationPairId),
            reason: text.id,
          );
          usedHyphenationPairIds.add(hyphenationPairId);
        }

        final visiblePair =
            '${_normalize(mistake.token)}->'
            '${_normalize(mistake.replacement)}';
        visiblePairCounts.update(
          visiblePair,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    expect(
      usedCommonPairIndices,
      equals(
        Set<int>.from(List<int>.generate(commonPairCount, (index) => index)),
      ),
    );
    expect(usedHyphenationPairIds, equals(hyphenationPairIds));
    expect(visiblePairCounts.values.every((count) => count <= 3), isTrue);
  });
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceFirst(RegExp(r'^\W+', unicode: true), '')
      .replaceFirst(RegExp(r'\W+$', unicode: true), '');
}
