import 'package:flutter_test/flutter_test.dart';
import 'package:jaga_tani/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JagaTaniApp());
    expect(find.byType(JagaTaniApp), findsOneWidget);
    // Advance time past the splash screen timer (2500ms)
    await tester.pump(const Duration(milliseconds: 3000));
  });
}
