import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/app/app.dart';

void main() {
  testWidgets('MaterialApp declares Romanian locale', (tester) async {
    await tester.pumpWidget(const LexioApp());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('ro'));
    expect(app.supportedLocales, contains(const Locale('ro')));
  });
}
