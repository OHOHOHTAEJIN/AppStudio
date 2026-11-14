import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docu_snap/main.dart';

void main() {
  testWidgets('main screen is rendered', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('도큐 스냅'), findsWidgets);
  });
}
