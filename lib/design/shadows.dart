import 'package:flutter/material.dart';

abstract class LexioShadows {
  LexioShadows._();

  static BoxShadow get subtle => BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 1),
      );

  static BoxShadow get card => BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 2),
      );

  static BoxShadow get elevated => BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 4),
      );

  static BoxShadow get floating => BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 32,
        offset: const Offset(0, 8),
      );

  static List<BoxShadow> get cardCombined => [subtle, card];

  static List<BoxShadow> get elevatedCombined => [card, elevated];
}
