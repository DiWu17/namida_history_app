import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:namida_history_app/main.dart';
import 'package:namida_history_app/providers/locale_provider.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleProvider(),
        child: const MyApp(),
      ),
    );
    expect(find.byType(MyApp), findsOneWidget);
  });
}
