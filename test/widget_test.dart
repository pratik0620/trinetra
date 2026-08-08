
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:women_safety_app/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RAKSHAApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(RAKSHAApp), findsOneWidget);
  });
}
