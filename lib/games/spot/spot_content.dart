import 'dart:convert';

import 'package:flutter/services.dart';

final class SpotMistake {
  final int wordIndex;
  final String token;
  final String replacement;
  final String explanation;
  final String category;
  final String topic;

  const SpotMistake({
    required this.wordIndex,
    required this.token,
    required this.replacement,
    required this.explanation,
    required this.category,
    required this.topic,
  });

  factory SpotMistake.fromJson(Map<String, dynamic> json) {
    return SpotMistake(
      wordIndex: json['wordIndex'] as int,
      token: json['token'] as String,
      replacement: json['replacement'] as String,
      explanation: json['explanation'] as String,
      category: json['category'] as String,
      topic: json['topic'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'wordIndex': wordIndex,
    'token': token,
    'replacement': replacement,
    'explanation': explanation,
    'category': category,
    'topic': topic,
  };
}

final class SpotText {
  final String id;
  final String type;
  final String title;
  final int difficulty;
  final String content;
  final List<SpotMistake> mistakes;
  late final List<String> _words;
  late final List<List<int>> _paragraphRanges;

  SpotText({
    required this.id,
    required this.type,
    required this.title,
    required this.difficulty,
    required this.content,
    required this.mistakes,
  }) {
    _words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    _paragraphRanges = _computeParagraphRanges();
  }

  factory SpotText.fromJson(Map<String, dynamic> json) {
    final mistakesJson = json['mistakes'] as List<dynamic>;
    return SpotText(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      difficulty: json['difficulty'] as int,
      content: json['content'] as String,
      mistakes: mistakesJson
          .map((m) => SpotMistake.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  List<String> get words => List.unmodifiable(_words);
  int get wordCount => _words.length;
  List<List<int>> get paragraphRanges => _paragraphRanges;

  List<List<int>> _computeParagraphRanges() {
    final paragraphs = content.split(RegExp(r'\n\n|\n\s*\n'));
    final ranges = <List<int>>[];
    int offset = 0;

    for (final p in paragraphs) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;
      final wordsInParagraph =
          trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      if (wordsInParagraph > 0) {
        ranges.add([offset, offset + wordsInParagraph - 1]);
        offset += wordsInParagraph;
      }
    }

    return ranges;
  }
}

final class SpotContent {
  SpotContent._();

  static List<SpotText>? _cached;

  static Future<List<SpotText>> load() async {
    if (_cached != null) return _cached!;

    final jsonString =
        await rootBundle.loadString('lib/content/spot_texts.json');
    final jsonList = json.decode(jsonString) as List<dynamic>;
    _cached = jsonList
        .map((item) => SpotText.fromJson(item as Map<String, dynamic>))
        .toList();
    return _cached!;
  }

  static List<SpotText> session(int count) {
    if (_cached == null || _cached!.isEmpty) return [];
    final shuffled = List<SpotText>.from(_cached!)..shuffle();
    return shuffled.take(count).toList();
  }
}
