import 'package:clinical_calendar/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('production composition root renders without prototype data', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();

    expect(find.text('CLINICAL CALENDAR'), findsOneWidget);
    expect(find.text('PRODUCTION FOUNDATION'), findsOneWidget);
    expect(find.textContaining('Clinical Session'), findsNothing);
  });
}
