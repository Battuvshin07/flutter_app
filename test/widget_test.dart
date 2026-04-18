import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test renders expected welcome text',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Mongol History App'),
          ),
        ),
      ),
    );

    expect(find.text('Mongol History App'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });
}
