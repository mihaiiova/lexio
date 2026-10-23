import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/privacy/privacy_screen.dart';

void main() {
  testWidgets('policy discloses pseudonymous collection and bounded deletion', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
    await tester.scrollUntilVisible(find.textContaining('pseudonime'), 300);
    expect(find.textContaining('pseudonime'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Păstrare și ștergere'), 300);
    expect(find.textContaining('91 de zile'), findsOneWidget);
    expect(find.textContaining('cinci instalări distincte'), findsOneWidget);
  });
}
