final class DifficultyCalibration {
  DifficultyCalibration._();

  static int vocabulary(String id) {
    final index = _index(id);
    if (index <= 15) return 1;
    if (index <= 35) return 2;
    if (index <= 50) return 3;
    if (index <= 70) return 4;
    return 5;
  }

  static int idiom(String id) {
    final index = _index(id);
    if (index <= 12) return 1;
    if (index <= 24) return 2;
    if (index <= 38) return 3;
    if (index <= 50) return 4;
    return 5;
  }

  static int grammar(String id, int sourceDifficulty) {
    final index = _index(id);
    if (sourceDifficulty == 1) return index >= 70 ? 2 : 1;
    if (sourceDifficulty == 2) return 3;
    return index >= 120 ? 5 : 4;
  }

  static int spotText(String id, int sourceDifficulty) {
    final index = _index(id);
    if (sourceDifficulty == 1) return index >= 40 ? 2 : 1;
    if (sourceDifficulty == 2) return 3;
    return index >= 37 ? 5 : 4;
  }

  static int _index(String id) =>
      int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}
