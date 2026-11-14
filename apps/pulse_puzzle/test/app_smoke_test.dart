import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulse_puzzle/main.dart';

void main() {
  test('each board contains exactly one target at all difficulties', () {
    final random = Random(42);
    for (final level in PuzzleLevel.values) {
      for (var n = 1; n <= level.maxNumber; n++) {
        final cells = createPuzzleBoard(random, level, n);
        expect(cells.length, level.cells);
        expect(cells.where((v) => v == n).length, 1);
        expect(cells.every((v) => v >= 1 && v <= level.maxNumber), isTrue);
      }
    }
    expect(puzzlePoints(0), 10);
    expect(puzzlePoints(3), 12);
  });

  testWidgets('game mode selection, start and pause work', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('펄스 퍼즐'), findsWidgets);
    await tester.tap(find.text('30초 스피드'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('puzzle-start')));
    await tester.tap(find.byKey(const Key('puzzle-start')));
    await tester.pump();
    expect(find.text('일시정지'), findsOneWidget);
    await tester.ensureVisible(find.text('일시정지'));
    await tester.tap(find.text('일시정지'));
    await tester.pump();
    expect(find.text('계속하기'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
