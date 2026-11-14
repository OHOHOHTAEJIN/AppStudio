import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:privacy_mosaic/main.dart';
import 'package:privacy_mosaic/privacy_engine.dart';

void main() {
  test('image masking changes selected region and preserves other pixels', () {
    final original = img.Image(width: 60, height: 60);
    img.fill(original, color: img.ColorRgb8(240, 120, 70));
    final source = Uint8List.fromList(img.encodeJpg(original));
    final normalized = normalizePhoto(source);
    final result = obscurePhoto(
      source: normalized,
      regions: const [PrivacyRegion(0.2, 0.2, 0.8, 0.8)],
      effect: PrivacyEffect.solid,
      intensity: 30,
    );
    final decoded = img.decodeJpg(result)!;
    expect(decoded.getPixel(30, 30).r.toInt(), lessThan(70));
    expect(decoded.getPixel(2, 2).r.toInt(), greaterThan(150));
    expect(normalized, isNotEmpty);
  });

  test('region coordinates normalize and reject a tiny rectangle', () {
    final region = PrivacyRegion.fromRect(const Rect.fromLTRB(-.3, .1, 1.2, .8));
    expect(region.left, 0.0);
    expect(region.right, 1.0);
    expect(const PrivacyRegion(0, 0, 0.001, .001).isValid, false);
  });

  testWidgets('privacy app has manual and automatic editing controls', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('사진 불러오기'), findsOneWidget);
  });
}
