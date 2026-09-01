import '../games/grammar/grammar_content.dart';
import '../games/idioms/idioms_content.dart';
import '../games/spot/spot_content.dart';
import '../games/vocabulary/vocabulary_content.dart';

/// Single source of truth that maps a game id to its total discoverable
/// notion count. Content loaders own the actual notion enumeration; this
/// helper only aggregates them for the home screen.
final class DiscoveryCatalog {
  DiscoveryCatalog._();

  static Future<Map<String, int>> totalNotionsByGame() async {
    await Future.wait([
      VocabularyContent.load(),
      IdiomsContent.load(),
      GrammarContent.load(),
      SpotContent.load(),
    ]);
    return {
      'grammar': GrammarContent.distinctNotionIds().length,
      'vocabulary': VocabularyContent.distinctNotionIds().length,
      'idioms': IdiomsContent.distinctNotionIds().length,
      'spot': SpotContent.distinctNotionIds().length,
    };
  }
}
