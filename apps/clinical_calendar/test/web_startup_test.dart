import 'package:clinical_calendar/main_web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('web startup fails closed until web storage is available', (
    tester,
  ) async {
    await tester.pumpWidget(web.buildWebRoot());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byKey(const Key('web-not-available')), findsOneWidget);
    expect(find.text('Clinical Calendar'), findsOneWidget);
    expect(find.text('Web support is not available yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
