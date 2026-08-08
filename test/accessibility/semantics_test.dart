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

  testWidgets('Home screen opens the in-app privacy policy', (tester) async {
    await tester.pumpWidget(const LexioApp());

    expect(find.text('Confidențialitate'), findsOneWidget);
    expect(find.text('Asistență'), findsNothing);

    await tester.ensureVisible(find.text('Confidențialitate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confidențialitate'));
    await tester.pumpAndSettle();

    expect(find.text('Politica de confidențialitate'), findsOneWidget);
    expect(find.text('Ce date colectăm'), findsOneWidget);
    expect(find.textContaining('Firebase Analytics'), findsWidgets);
  });

  testWidgets('App title text is present', (tester) async {
    await tester.pumpWidget(const LexioApp());
    expect(find.text('Slove'), findsOneWidget);
  });
}
