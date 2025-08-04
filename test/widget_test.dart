import 'package:flutter_test/flutter_test.dart';
import 'package:makro/main.dart';

void main() {
  testWidgets('MakroApp smoke test', (WidgetTester tester) async {
    // Instantiate your real root widget:
    await tester.pumpWidget(const MakroApp());

    // Verify it builds:
    expect(find.byType(MakroApp), findsOneWidget);
  });
}
