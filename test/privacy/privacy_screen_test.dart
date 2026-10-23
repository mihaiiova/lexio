import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/privacy/privacy_screen.dart';

void main() {
  testWidgets(
    'privacy details explain collection, installation identity and deletion limits',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
      await tester.scrollUntilVisible(find.text('Ce informații trimitem'), 300);
      expect(
        find.textContaining('Nu trimitem cuvintele apăsate'),
        findsOneWidget,
      );
      expect(find.textContaining('nu răspunsul ales'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Un identificator pentru această instalare'),
        300,
      );
      expect(find.textContaining('nu sunt complet anonime'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Cum oprești analiza'), 300);
      expect(find.textContaining('se oprește imediat'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Cum ceri ștergerea'), 300);
      expect(find.textContaining('Este nevoie de internet'), findsOneWidget);
      expect(
        find.textContaining('analiza nu poate fi reactivată'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Cât timp păstrăm datele'),
        300,
      );
      expect(find.textContaining('expiră după 90 de zile'), findsOneWidget);
      expect(
        find.textContaining('Cererile repetate nu prelungesc'),
        findsOneWidget,
      );
      expect(find.textContaining('defecțiune'), findsOneWidget);
      expect(find.textContaining('91 de zile'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Ce poate rămâne după ștergere'),
        300,
      );
      expect(find.textContaining('nu mai pot fi retrase'), findsOneWidget);
      expect(find.textContaining('cinci instalări distincte'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Dacă nu e internet sau alegerea nu se salvează'),
        300,
      );
      expect(find.textContaining('poate reveni setarea veche'), findsOneWidget);
    },
  );
}
