import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulse_puzzle/main.dart';

void main() {
  testWidgets('main screen is rendered', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('펄스 퍼즐'), findsWidgets);
  });
}
