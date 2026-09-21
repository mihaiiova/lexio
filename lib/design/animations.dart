import 'package:flutter/material.dart';

abstract class LexioDurations {
  LexioDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration reveal = Duration(milliseconds: 600);
  static const Duration page = Duration(milliseconds: 350);
  static const Duration shake = Duration(milliseconds: 400);
  static const Duration feedback = Duration(milliseconds: 450);
}

abstract class LexioCurves {
  LexioCurves._();

  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring = Curves.elasticOut;
  static const Curve smooth = Cubic(0.22, 0.61, 0.36, 1);
  static const Curve bouncy = Cubic(0.34, 1.56, 0.64, 1);
}
