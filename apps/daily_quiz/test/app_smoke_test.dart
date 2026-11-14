import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_quiz/main.dart';

void main() {
  testWidgets('main screen is rendered', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('데일리 퀴즈'), findsWidgets);
  });
}
