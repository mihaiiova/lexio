import 'package:flutter/material.dart';

sealed class LexioTextStyles {
  LexioTextStyles._();

  static const _defaultLetterSpacing = -0.2;

  // Display
  static TextStyle get displayLarge => const TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: _defaultLetterSpacing,
  );

  static TextStyle get displayMedium => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: _defaultLetterSpacing,
  );

  // Sentence (game content only)
  static TextStyle get sentence => const TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: _defaultLetterSpacing,
  );

  // Heading
  static TextStyle get headingLarge => const TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: _defaultLetterSpacing,
  );

  static TextStyle get headingMedium => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: _defaultLetterSpacing,
  );

  static TextStyle get headingSmall => const TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: _defaultLetterSpacing,
  );

  // Body
  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: _defaultLetterSpacing,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: _defaultLetterSpacing,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: _defaultLetterSpacing,
  );

  // Label
  static TextStyle get labelLarge => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static TextStyle get labelMedium => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static TextStyle get labelSmall => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.4,
  );

  // Utility
  static TextStyle get accentLarge => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    height: 1.4,
    letterSpacing: _defaultLetterSpacing,
  );

  static TextStyle get monoSmall => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFamily: 'monospace',
  );
}
