import '../games/grammar/grammar_content.dart';
import '../games/idioms/idioms_content.dart';
import '../games/spot/spot_content.dart';
import '../games/vocabulary/vocabulary_content.dart';

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
