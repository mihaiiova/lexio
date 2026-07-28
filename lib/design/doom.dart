final class DoomUrl {
  DoomUrl._();

  static const String _baseUrl = 'https://doom.lingv.ro/cautare/q';

  static String forWord(String word) {
    final encoded = Uri.encodeComponent(word.trim());
    return '$_baseUrl/$encoded';
  }
}
