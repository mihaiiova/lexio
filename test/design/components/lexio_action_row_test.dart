import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/components/lexio_action_row.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/spacing.dart';

void main() {
  testWidgets('insets its separator from both screen edges', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LexioActionRow(label: 'Joacă din nou', onPressed: () {}),
        ),
      ),
    );

    final separator = find.byType(Divider);
    expect(tester.getTopLeft(separator).dx, LexioSpacing.screenHorizontal);
    expect(
      tester.getBottomRight(separator).dx,
      390 - LexioSpacing.screenHorizontal,
    );
  });
}
