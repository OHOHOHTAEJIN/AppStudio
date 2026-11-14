// ignore_for_file: prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Normalized bounding box; never contains source pixel coordinates.
class PrivacyRegion {
  const PrivacyRegion(this.left, this.top, this.right, this.bottom,
      {this.reason = '직접 지정'});
  final double left, top, right, bottom;
  final String reason;

  factory PrivacyRegion.fromRect(Rect rect, {String reason = '직접 지정'}) {
    return PrivacyRegion(
      rect.left.clamp(0.0, 1.0).toDouble(),
      rect.top.clamp(0.0, 1.0).toDouble(),
      rect.right.clamp(0.0, 1.0).toDouble(),
      rect.bottom.clamp(0.0, 1.0).toDouble(),
      reason: reason,
    );
  }

  bool get isValid => right - left > 0.008 && bottom - top > 0.008;
  Rect get rect => Rect.fromLTRB(left, top, right, bottom);
}

enum PrivacyEffect { mosaic, blur, solid }

/// Returns a *new* JPEG with a fresh pixel buffer and no original EXIF/GPS.
Uint8List normalizePhoto(Uint8List bytes) {
  final src = img.decodeImage(bytes);
  if (src == null) throw const FormatException('이미지를 읽을 수 없습니다.');
  var oriented = img.bakeOrientation(src);
  if (oriented.width > 2560 || oriented.height > 2560) {
    if (oriented.width >= oriented.height) {
      oriented = img.copyResize(oriented, width: 2560);
    } else {
      oriented = img.copyResize(oriented, height: 2560);
    }
  }
  // Construct a new image, rather than copying the EXIF-bearing image object.
  final clean = img.Image(width: oriented.width, height: oriented.height);
  img.compositeImage(clean, oriented);
  return Uint8List.fromList(img.encodeJpg(clean, quality: 94));
}

Uint8List obscurePhoto({
  required Uint8List source,
  required List<PrivacyRegion> regions,
  required PrivacyEffect effect,
  required int intensity,
}) {
  final decoded = img.decodeImage(source);
  if (decoded == null) throw const FormatException('이미지 변환 실패');
  final original = img.Image(width: decoded.width, height: decoded.height);
  img.compositeImage(original, decoded);
  if (regions.isEmpty) return Uint8List.fromList(img.encodeJpg(original, quality: 92));

  final mask = img.Image(width: original.width, height: original.height);
  img.fill(mask, color: img.ColorRgb8(0, 0, 0));
  for (final region in regions.where((r) => r.isValid)) {
    final x1 = (region.left * original.width).floor().clamp(0, original.width - 1);
    final y1 = (region.top * original.height).floor().clamp(0, original.height - 1);
    final x2 = (region.right * original.width).ceil().clamp(0, original.width - 1);
    final y2 = (region.bottom * original.height).ceil().clamp(0, original.height - 1);
    if (effect == PrivacyEffect.solid) {
      img.fillRect(original, x1: x1, y1: y1, x2: x2, y2: y2,
          color: img.ColorRgb8(8, 13, 23));
    } else {
      img.fillRect(mask, x1: x1, y1: y1, x2: x2, y2: y2,
          color: img.ColorRgb8(255, 255, 255));
    }
  }
  if (effect == PrivacyEffect.mosaic) {
    img.pixelate(original,
      size: math.max(8, intensity),
      mode: img.PixelateMode.average,
      mask: mask);
  } else if (effect == PrivacyEffect.blur) {
    img.gaussianBlur(original, radius: math.max(2, intensity ~/ 3), mask: mask);
  }
  return Uint8List.fromList(img.encodeJpg(original, quality: 92));
}
