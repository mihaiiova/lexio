import 'package:flutter_test/flutter_test.dart';

import 'package:lexio/app/app.dart';

void main() {
  testWidgets('Home screen renders all game titles', (tester) async {
    await tester.pumpWidget(const LexioApp());

    expect(find.text('Corect sau greșit?'), findsOneWidget);
    expect(find.text('Ce înseamnă?'), findsOneWidget);
    expect(find.text('Vorba vine'), findsOneWidget);
    expect(find.text('Găsește greșeala'), findsOneWidget);
  });

  testWidgets('Home screen has legal footer links', (tester) async {
    await tester.pumpWidget(const LexioApp());
    expect(find.text('Confidențialitate'), findsOneWidget);
    expect(find.text('Asistență'), findsOneWidget);
  });

  testWidgets('App title text is present', (tester) async {
    await tester.pumpWidget(const LexioApp());
    expect(find.text('Slove'), findsOneWidget);
  });
}
