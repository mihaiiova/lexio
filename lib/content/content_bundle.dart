import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../games/grammar/grammar_content.dart';
import '../games/idioms/idioms_content.dart';
import '../games/spot/spot_content.dart';
import '../games/vocabulary/vocabulary_content.dart';
import 'hyphenation_content.dart';

/// A complete, validated content snapshot that can be served in place of the
/// bundled assets.
///
/// Both the bundled assets and a downloaded `content_bundle.json` parse through
/// this class, so the domain models and their notion identities are identical
/// regardless of source.
final class ContentBundle {
  const ContentBundle({
    required this.schemaVersion,
    required this.grammar,
    required this.vocabulary,
    required this.idioms,
    required this.spotTexts,
  });

  static const supportedSchemaVersion = 1;

  final int schemaVersion;
  final List<GrammarExercise> grammar;
  final List<VocabularyExercise> vocabulary;
  final List<IdiomExercise> idioms;
  final List<SpotText> spotTexts;

  factory ContentBundle.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int || schemaVersion != supportedSchemaVersion) {
      throw const FormatException('unsupported content bundle schema version');
    }

    final grammarJson = _requiredList(json, 'grammar');
    final vocabularyJson = _requiredList(json, 'vocabulary');
    final idiomsJson = _requiredList(json, 'idioms');
    final spotJson = _requiredList(json, 'spotTexts');
    final hyphenationJson = _requiredList(json, 'hyphenationPairs');
    final commonErrorsJson = _requiredList(json, 'commonErrorPairs');
    for (final entry in commonErrorsJson) {
      if (entry is! Map<String, dynamic> ||
          entry['notionId'] is! String ||
          (entry['notionId'] as String).isEmpty) {
        throw const FormatException('invalid common error pair');
      }
    }

    final hyphenationPairs = HyphenationContent.parse(hyphenationJson);

    return ContentBundle(
      schemaVersion: schemaVersion,
      grammar: GrammarContent.parse(grammarJson, hyphenationPairs),
      vocabulary: VocabularyContent.parse(vocabularyJson),
      idioms: IdiomsContent.parse(idiomsJson),
      spotTexts: SpotContent.parse(spotJson),
    );
  }

  static List<dynamic> _requiredList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List<dynamic>) {
      throw FormatException('content bundle field "$key" must be a list');
    }
    return value;
  }

  factory ContentBundle.fromString(String source) {
    final decoded = json.decode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('content bundle must be a JSON object');
    }
    return ContentBundle.fromJson(decoded);
  }

  /// Parses the canonical bundled assets into the same shape a remote bundle
  /// would have, so bundled content can be activated through one code path.
  static Future<ContentBundle> loadBundled() async {
    final grammarJson =
        json.decode(
              await rootBundle.loadString('lib/content/grammar_exercises.json'),
            )
            as List<dynamic>;
    final vocabularyJson =
        json.decode(
              await rootBundle.loadString(
                'lib/content/vocabulary_exercises.json',
              ),
            )
            as List<dynamic>;
    final idiomsJson =
        json.decode(
              await rootBundle.loadString('lib/content/idiom_exercises.json'),
            )
            as List<dynamic>;
    final spotJson =
        json.decode(await rootBundle.loadString('lib/content/spot_texts.json'))
            as List<dynamic>;
    final hyphenationJson =
        json.decode(await rootBundle.loadString('data/hyphenation_pairs.json'))
            as List<dynamic>;

    return ContentBundle(
      schemaVersion: supportedSchemaVersion,
      grammar: GrammarContent.parse(
        grammarJson,
        HyphenationContent.parse(hyphenationJson),
      ),
      vocabulary: VocabularyContent.parse(vocabularyJson),
      idioms: IdiomsContent.parse(idiomsJson),
      spotTexts: SpotContent.parse(spotJson),
    );
  }

  /// Activates this snapshot as the content source for subsequent rounds.
  ///
  /// A screen keeps the content snapshot with which it started, so calling
  /// this only affects the next round, never an active one.
  void apply() {
    GrammarContent.seed(grammar);
    VocabularyContent.seed(vocabulary);
    IdiomsContent.seed(idioms);
    SpotContent.seed(spotTexts);
  }
}
