import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_slim/main.dart';

void main() {
  test('media size formatting', () {
    expect(formatMediaSize(1), '1 B');
    expect(formatMediaSize(1024), '1.0 KB');
    expect(formatMediaSize(1048576), '1.00 MB');
  });

  testWidgets('photo and video tabs have clear actions', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('사진 압축하기'), findsOneWidget);
    await tester.tap(find.text('동영상'));
    await tester.pump();
    expect(find.text('동영상 선택'), findsOneWidget);
  });
}
