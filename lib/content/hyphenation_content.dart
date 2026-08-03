import 'dart:convert';

import 'package:flutter/services.dart';

final class HyphenationPair {
  final String id;
  final String hyphenatedForm;
  final List<String> components;
  final String hyphenatedExplanation;
  final String hyphenatedExample;
  final String unhyphenatedForm;
  final bool unhyphenatedIsValid;
  final String? unhyphenatedExplanation;
  final String? unhyphenatedExample;

  const HyphenationPair({
    required this.id,
    required this.hyphenatedForm,
    required this.components,
    required this.hyphenatedExplanation,
    required this.hyphenatedExample,
    required this.unhyphenatedForm,
    required this.unhyphenatedIsValid,
    required this.unhyphenatedExplanation,
    required this.unhyphenatedExample,
  });

  factory HyphenationPair.fromJson(Map<String, dynamic> json) {
    return HyphenationPair(
      id: json['id'] as String,
      hyphenatedForm: json['hyphenatedForm'] as String,
      components: (json['components'] as List<dynamic>).cast<String>(),
      hyphenatedExplanation: json['hyphenatedExplanation'] as String,
      hyphenatedExample: json['hyphenatedExample'] as String,
      unhyphenatedForm: json['unhyphenatedForm'] as String,
      unhyphenatedIsValid: json['unhyphenatedIsValid'] as bool,
      unhyphenatedExplanation: json['unhyphenatedExplanation'] as String?,
      unhyphenatedExample: json['unhyphenatedExample'] as String?,
    );
  }

  String get missingHyphenExample => _replaceForm(
    sentence: hyphenatedExample,
    form: hyphenatedForm,
    replacement: unhyphenatedForm,
  );

  String? get unnecessaryHyphenExample {
    final example = unhyphenatedExample;
    if (!unhyphenatedIsValid || example == null) return null;
    return _replaceForm(
      sentence: example,
      form: unhyphenatedForm,
      replacement: hyphenatedForm,
    );
  }

  static String _replaceForm({
    required String sentence,
    required String form,
    required String replacement,
  }) {
    final match = RegExp(
      RegExp.escape(form),
      caseSensitive: false,
    ).firstMatch(sentence);
    if (match == null) {
      throw FormatException('Forma „$form” lipsește din exemplul „$sentence”.');
    }

    final matchedForm = match.group(0)!;
    final preservesInitialCapital =
        matchedForm[0] == matchedForm[0].toUpperCase();
    final adjustedReplacement = preservesInitialCapital
        ? '${replacement[0].toUpperCase()}${replacement.substring(1)}'
        : replacement;

    return sentence.replaceRange(match.start, match.end, adjustedReplacement);
  }
}

final class HyphenationContent {
  HyphenationContent._();

  static List<HyphenationPair>? _cached;

  static Future<List<HyphenationPair>> load() async {
    if (_cached != null) return _cached!;

    final jsonString = await rootBundle.loadString(
      'data/hyphenation_pairs.json',
    );
    final entries = json.decode(jsonString) as List<dynamic>;
    _cached = entries
        .map((entry) => HyphenationPair.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
    return _cached!;
  }
}
