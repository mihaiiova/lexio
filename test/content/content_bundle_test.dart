import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/content/content_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'generated bundle parses into the same domain models as bundled assets',
    () async {
      final file = File('content_public/content_bundle.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'run generate_content_bundle.py',
      );

      final bundle = ContentBundle.fromString(await file.readAsString());
      final bundled = await ContentBundle.loadBundled();

      expect(bundle.schemaVersion, ContentBundle.supportedSchemaVersion);
      expect(bundle.grammar, hasLength(bundled.grammar.length));
      expect(bundle.vocabulary, hasLength(bundled.vocabulary.length));
      expect(bundle.idioms, hasLength(bundled.idioms.length));
      expect(bundle.spotTexts, hasLength(bundled.spotTexts.length));

      expect(
        bundle.grammar.map((e) => e.notionId).toSet(),
        equals(bundled.grammar.map((e) => e.notionId).toSet()),
      );
      expect(
        bundle.vocabulary.map((e) => e.notionId).toSet(),
        equals(bundled.vocabulary.map((e) => e.notionId).toSet()),
      );
      expect(
        bundle.idioms.map((e) => e.notionId).toSet(),
        equals(bundled.idioms.map((e) => e.notionId).toSet()),
      );
      expect(
        bundle.spotTexts.expand((t) => t.mistakeNotionIds).toSet(),
        equals(bundled.spotTexts.expand((t) => t.mistakeNotionIds).toSet()),
      );
    },
  );

  test('rejects a malformed bundle string', () {
    expect(() => ContentBundle.fromString('{not json'), throwsFormatException);
  });

  test('rejects an unsupported bundle schema version', () {
    expect(
      () => ContentBundle.fromString('{"schemaVersion": 99}'),
      throwsFormatException,
    );
  });

  test('rejects a bundle missing a required section', () {
    expect(
      () => ContentBundle.fromString(
        '{"schemaVersion": 1, "grammar": [], "vocabulary": [], '
        '"idioms": [], "spotTexts": [], "hyphenationPairs": []}',
      ),
      throwsFormatException,
    );
  });
}
