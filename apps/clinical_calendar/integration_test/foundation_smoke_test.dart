import 'package:clinical_calendar/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('production foundation launches', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    expect(find.text('PRODUCTION FOUNDATION'), findsOneWidget);
  });
}
