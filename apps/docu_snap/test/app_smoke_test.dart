import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:docu_snap/main.dart';

void main() {
  test('scan enhancement returns a decodable JPEG', () {
    final source = img.encodeJpg(img.Image(width: 8, height: 8));
    final processed = enhanceScan(source);
    expect(processed, isNotEmpty);
    expect(img.decodeJpg(processed), isNotNull);
  });

  testWidgets('document screen exposes capture, PDF and OCR actions', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('문서 촬영'), findsOneWidget);
    expect(find.byKey(const Key('pdf-create')), findsOneWidget);
    expect(find.text('한국어'), findsOneWidget);
  });
}
