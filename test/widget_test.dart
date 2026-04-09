import 'package:flutter_test/flutter_test.dart';

import 'package:namida_history_app/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Verify the app renders successfully
    expect(find.byType(MyApp), findsOneWidget);
  });
}
