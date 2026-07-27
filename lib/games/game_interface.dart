import 'package:flutter/material.dart';

abstract class LexioGame {
  String get id;
  String get title;
  String get description;
  String get emoji;
  Color? get accentColor;
  Widget buildScreen(BuildContext context);
}
