import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_slim/main.dart';

void main() {
  testWidgets('main screen is rendered', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('픽셀 슬림'), findsWidgets);
  });
}
