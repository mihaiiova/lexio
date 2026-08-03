import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lexio/app/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LexioApp());

    expect(find.text('Lexio'), findsNothing);
    expect(find.text('Provocarea zilei'), findsNothing);
    expect(find.text('Alege un joc'), findsNothing);
    expect(find.text('Corect sau greșit?'), findsOneWidget);
    expect(find.text('Ce înseamnă?'), findsOneWidget);
    expect(find.text('Vorba vine'), findsOneWidget);
    expect(find.text('Găsește greșeala'), findsOneWidget);
    expect(find.text('În pregătire'), findsNothing);

    final entries = find.byType(InkWell);
    expect(entries, findsNWidgets(4));

    final firstEntry = tester.getRect(entries.at(0));
    final lastEntry = tester.getRect(entries.at(3));
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(
      (firstEntry.top - (viewportHeight - lastEntry.bottom)).abs(),
      lessThan(1),
    );
  });
}
