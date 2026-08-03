import 'package:flutter_test/flutter_test.dart';

import 'package:lexio/app/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LexioApp());

    expect(find.text('Lexio'), findsOneWidget);
    expect(find.text('Jocuri cu cuvinte în limba română'), findsOneWidget);
    expect(find.text('Provocarea zilei'), findsOneWidget);
    expect(find.text('Alege un joc'), findsOneWidget);
    expect(find.text('Ce înseamnă?'), findsOneWidget);
    expect(find.text('Vorba vine'), findsOneWidget);
    expect(find.text('Găsește greșeala'), findsOneWidget);
    expect(find.text('În pregătire'), findsOneWidget);
  });
}
