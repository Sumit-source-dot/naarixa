import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:naarixa/app/app.dart'; // ✅ updated package name

void main() {
  testWidgets('Naarixa loads bottom tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NaarixaApp(), // ✅ updated class name
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}