import 'package:flutter_test/flutter_test.dart';

import 'package:matchly_app/main.dart';

void main() {
  testWidgets('Matchly app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MatchlyApp());
    await tester.pump();
    // App renders without crashing and shows the home screen title area.
    expect(find.text('TOPLAM BEKLENTİ'), findsOneWidget);
  });
}
