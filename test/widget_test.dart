import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lexio/app/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LexioApp());

    expect(find.text('Slove'), findsOneWidget);
    expect(find.text('Provocarea zilei'), findsNothing);
    expect(find.text('Alege un joc'), findsNothing);
    expect(find.text('Corect sau greșit?'), findsOneWidget);
    expect(find.text('Ce înseamnă?'), findsOneWidget);
    expect(find.text('Vorba vine'), findsOneWidget);
    expect(find.text('Găsește greșeala'), findsOneWidget);
    expect(find.text('În pregătire'), findsNothing);

    expect(find.byType(InkWell), findsNWidgets(6));
  });
}
