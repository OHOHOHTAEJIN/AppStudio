import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.length != 1 || !['privacy_mosaic', 'shift_pay'].contains(args.first)) {
    stderr.writeln('Usage: dart run tool/generate_icon.dart privacy_mosaic|shift_pay');
    exitCode = 2;
    return;
  }
  final privacy = args.first == 'privacy_mosaic';
  const width = 512;
  final output = img.Image(width: width, height: width);
  for (final pixel in output) {
    final x = pixel.x.toDouble();
    final y = pixel.y.toDouble();
    final gradient = .35 * (1 - y / 512) + .18 * x / 512;
    var r = privacy ? 8.0 + 12 * gradient : 14.0 + 18 * gradient;
    var g = privacy ? 26.0 + 26 * gradient : 20.0 + 19 * gradient;
    var b = privacy ? 42.0 + 32 * gradient : 61.0 + 28 * gradient;
    // Glowing ambient blob adds depth without relying on a raster source.
    final dx = x - (privacy ? 410 : 395);
    final dy = y - 112;
    final glow = math.exp(-(dx * dx + dy * dy) / (2 * 115 * 115));
    r += (privacy ? 20 : 34) * glow;
    g += (privacy ? 71 : 43) * glow;
    b += (privacy ? 56 : 87) * glow;
    final centerX = x - 256;
    final centerY = y - 248;

    if (privacy) {
      // Rounded outer shield with narrowing lower tip.
      final normalizedY = (y - 96) / 340;
      final halfWidth = normalizedY < .57
          ? 154.0 : 154 * (1 - (normalizedY - .57) / .55).clamp(.0, 1.0);
      final shield = normalizedY >= 0 && normalizedY <= 1 &&
          centerX.abs() <= halfWidth &&
          (y >= 140 || (centerX.abs() - 115).clamp(0, 40) <= y - 96);
      if (shield) {
        r = 35; g = 215 - normalizedY * 44; b = 202 + 25 * normalizedY;
        final inner = y > 117 && y < 408 &&
            centerX.abs() < halfWidth - 16;
        if (inner) { r = 10; g = 60; b = 72; }
      }
      // 3-by-3 pixel-mosaic symbol centered in the shield.
      if (x >= 192 && x < 320 && y >= 192 && y < 319) {
        final col = ((x - 192) ~/ 44);
        final row = ((y - 192) ~/ 44);
        final localX = (x - 192) % 44;
        final localY = (y - 192) % 44;
        if (localX >= 5 && localX < 39 && localY >= 5 && localY < 39) {
          final bright = (row + col) % 3 == 0;
          r = bright ? 183 : 38;
          g = bright ? 255 : 200;
          b = bright ? 238 : 199;
        }
      }
    } else {
      // Rounded calendar tile.
      final inside = x >= 111 && x <= 401 && y >= 120 && y <= 405;
      final cornerX = x < 145 ? 145 - x : x > 367 ? x - 367 : 0.0;
      final cornerY = y < 154 ? 154 - y : y > 371 ? y - 371 : 0.0;
      if (inside && cornerX * cornerX + cornerY * cornerY < 34 * 34) {
        r = 106; g = 152; b = 251;
        if (x > 125 && x < 387 && y > 139 && y < 391) {
          r = 24; g = 48; b = 88;
        }
        if (y > 174 && y < 204 && x > 126 && x < 386) {
          r = 102; g = 157; b = 250;
        }
        // Three schedule lines and a currency-inspired growth chart.
        for (var k = 0; k < 3; k++) {
          if (x >= 170 && x <= 335 && y >= 235 + 43 * k &&
              y < 249 + 43 * k) {
            r = k == 2 ? 101 : 196; g = k == 2 ? 244 : 211; b = 249;
          }
        }
        if (x >= 147 && x <= 157 && y > 238 && y < 340) {
          r = 89; g = 252; b = 217;
        }
      }
    }
    pixel
      ..r = r.round().clamp(0, 255)
      ..g = g.round().clamp(0, 255)
      ..b = b.round().clamp(0, 255);
  }
  final file = File('assets/icon/launcher.png');
  file.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(output));
  stdout.writeln('Generated launcher: ' + file.path);
}
