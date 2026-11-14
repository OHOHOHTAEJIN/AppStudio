// ignore_for_file: prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures
import 'dart:io';
import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'privacy_engine.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const StudioApp(
    title: '모자이크 가드',
    accent: Color(0xFF5AE0CD),
    home: PrivacyEditorPage(),
  );
}

class PrivacyEditorPage extends StatefulWidget {
  const PrivacyEditorPage({super.key});
  @override
  State<PrivacyEditorPage> createState() => _PrivacyEditorPageState();
}

class _PrivacyEditorPageState extends State<PrivacyEditorPage> {
  Uint8List? _photo;
  Uint8List? _output;
  String? _normalizedPath;
  int _imageWidth = 1, _imageHeight = 1;
  bool _busy = false;
  final List<PrivacyRegion> _regions = [];
  PrivacyRegion? _removed;
  Offset? _dragStart;
  Offset? _dragCurrent;
  PrivacyEffect _effect = PrivacyEffect.mosaic;
  int _strength = 26;
  String? _notice;
  int _detectedFaces = 0, _detectedText = 0;

  Future<void> _selectPhoto() async {
    if (_busy) return;
    try {
      final photo = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (photo == null) return;
      setState(() { _busy = true; _notice = null; });
      final bytes = await compute(normalizePhoto, await photo.readAsBytes());
      final decoded = img.decodeJpg(bytes);
      if (decoded == null) throw const FormatException('사진 형식을 확인해 주세요.');
      final dir = await getTemporaryDirectory();
      final path = dir.path + '/privacy_original_' +
          DateTime.now().microsecondsSinceEpoch.toString() + '.jpg';
      await File(path).writeAsBytes(bytes);
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _output = null;
        _normalizedPath = path;
        _imageWidth = decoded.width;
        _imageHeight = decoded.height;
        _regions.clear();
        _removed = null;
        _detectedFaces = 0;
        _detectedText = 0;
      });
    } catch (e) {
      if (mounted) setState(() => _notice = '사진을 불러오지 못했습니다: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addRegion(PrivacyRegion region) {
    if (!region.isValid) return;
    setState(() {
      _regions.add(region);
      _removed = null;
      _output = null;
    });
  }

  void _undo() {
    if (_regions.isEmpty || _busy) return;
    setState(() {
      _removed = _regions.removeLast();
      _output = null;
    });
  }

  void _redo() {
    if (_removed == null || _busy) return;
    setState(() {
      _regions.add(_removed!);
      _removed = null;
      _output = null;
    });
  }

  Future<void> _detectFaces() async {
    final path = _normalizedPath;
    if (path == null || _busy) return;
    setState(() { _busy = true; _notice = null; });
    final detector = FaceDetector(options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: false,
    ));
    try {
      final faces = await detector.processImage(InputImage.fromFilePath(path));
      final newRegions = faces.map((face) {
        final b = face.boundingBox;
        const margin = 0.02;
        return PrivacyRegion.fromRect(Rect.fromLTRB(
          b.left / _imageWidth - margin,
          b.top / _imageHeight - margin,
          b.right / _imageWidth + margin,
          b.bottom / _imageHeight + margin,
        ), reason: '얼굴 자동 감지');
      }).where((r) => r.isValid).toList();
      if (!mounted) return;
      setState(() {
        _regions.addAll(newRegions);
        _detectedFaces = newRegions.length;
        _removed = null;
        _output = null;
        _notice = newRegions.isEmpty
            ? '얼굴을 찾지 못했습니다. 손가락으로 직접 가려주세요.'
            : '얼굴 ' + newRegions.length.toString() + '개를 선택했습니다. 범위를 확인하세요.';
      });
    } catch (e) {
      if (mounted) setState(() => _notice = '얼굴 감지 실패: $e');
    } finally {
      await detector.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _detectText() async {
    final path = _normalizedPath;
    if (path == null || _busy) return;
    setState(() { _busy = true; _notice = null; });
    final detector = TextRecognizer(script: TextRecognitionScript.korean);
    try {
      final result = await detector.processImage(InputImage.fromFilePath(path));
      final regions = result.blocks.map((block) {
        final b = block.boundingBox;
        const margin = 0.01;
        return PrivacyRegion.fromRect(Rect.fromLTRB(
          b.left / _imageWidth - margin,
          b.top / _imageHeight - margin,
          b.right / _imageWidth + margin,
          b.bottom / _imageHeight + margin,
        ), reason: '문자 자동 감지');
      }).where((r) => r.isValid).toList();
      if (!mounted) return;
      setState(() {
        _regions.addAll(regions);
        _detectedText = regions.length;
        _removed = null;
        _output = null;
        _notice = regions.isEmpty
          ? '문자를 찾지 못했습니다. 차량번호나 이름 영역은 직접 지정할 수 있습니다.'
          : '문자 ' + regions.length.toString() + '개 영역을 선택했습니다. 필요 없는 영역은 삭제하세요.';
      });
    } catch (e) {
      if (mounted) setState(() => _notice = '문자 감지 실패: $e');
    } finally {
      await detector.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    final source = _photo;
    if (source == null || _regions.isEmpty || _busy) return;
    setState(() { _busy = true; _notice = null; });
    try {
      // The engine creates a fresh JPEG without GPS/EXIF from normalized pixels.
      final result = await compute(_render, <String, Object>{
        'bytes': source, 'regions': List<PrivacyRegion>.from(_regions),
        'effect': _effect.index, 'strength': _strength,
      });
      if (!mounted) return;
      setState(() {
        _output = result;
        _notice = '가리기 완료. 결과를 확인한 후 공유·저장하세요.';
      });
    } catch (e) {
      if (mounted) setState(() => _notice = '이미지 처리 오류: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static Uint8List _render(Map<String, Object> input) => obscurePhoto(
    source: input['bytes']! as Uint8List,
    regions: input['regions']! as List<PrivacyRegion>,
    effect: PrivacyEffect.values[input['effect']! as int],
    intensity: input['strength']! as int,
  );

  Future<void> _share() async {
    if (_output == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File(dir.path + '/mosaic_guard_' +
          DateTime.now().millisecondsSinceEpoch.toString() + '.jpg');
      await file.writeAsBytes(_output!);
      await Share.shareXFiles([XFile(file.path)], text: '모자이크 가드 편집 사진');
    } catch (e) {
      if (mounted) setState(() => _notice = '공유 메뉴를 열 수 없습니다: $e');
    }
  }

  void _dragEnd(Size size) {
    if (_dragStart == null || _dragCurrent == null) return;
    final a = _dragStart!;
    final b = _dragCurrent!;
    final box = Rect.fromLTRB(
      (a.dx < b.dx ? a.dx : b.dx) / size.width,
      (a.dy < b.dy ? a.dy : b.dy) / size.height,
      (a.dx > b.dx ? a.dx : b.dx) / size.width,
      (a.dy > b.dy ? a.dy : b.dy) / size.height,
    );
    _dragStart = null;
    _dragCurrent = null;
    _addRegion(PrivacyRegion.fromRect(box));
  }

  @override
  Widget build(BuildContext context) => StudioScreen(
    title: '모자이크 가드',
    subtitle: '얼굴·이름·차량번호·개인정보를 사진에서 직접 가려보세요.',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const StudioHero(
        icon: Icons.privacy_tip_outlined,
        title: '사진을 공유하기 전, 한 번 더',
        description: '얼굴과 문자를 찾아 가리고, 손가락으로 영역을 추가하세요.',
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _busy ? null : _selectPhoto,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(_photo == null ? '사진 불러오기' : '다른 사진 불러오기'),
      ),
      const SizedBox(height: 14),
      if (_photo != null) ...[
        StudioSectionTitle(
          title: '사진에서 영역 선택',
          subtitle: '손가락으로 가릴 부분을 드래그하세요.',
          trailing: Text('선택 ' + _regions.length.toString() + '개'),
        ),
        StudioCard(child: Column(children: [
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = width * _imageHeight / _imageWidth;
            return SizedBox(
              width: width, height: height,
              child: GestureDetector(
                key: const Key('mask-edit-area'),
                behavior: HitTestBehavior.opaque,
                onPanStart: _busy ? null : (e) => setState(() {
                  _dragStart = e.localPosition;
                  _dragCurrent = e.localPosition;
                }),
                onPanUpdate: _busy ? null : (e) => setState(() {
                  _dragCurrent = e.localPosition;
                }),
                onPanEnd: _busy ? null : (_) => setState(() => _dragEnd(Size(width, height))),
                child: Stack(fit: StackFit.expand, children: [
                  Image.memory(_photo!, fit: BoxFit.fill, gaplessPlayback: true),
                  IgnorePointer(child: CustomPaint(
                    painter: _PrivacyOverlay(
                      _regions,
                      _dragStart == null || _dragCurrent == null ? null :
                        Rect.fromPoints(_dragStart!, _dragCurrent!),
                    ),
                  )),
                ]),
              ),
            );
          }),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _detectFaces,
              icon: const Icon(Icons.face_outlined),
              label: const Text('얼굴 찾기'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _detectText,
              icon: const Icon(Icons.text_fields_outlined),
              label: const Text('문자 찾기'),
            ),
            IconButton(tooltip: '마지막 영역 취소', onPressed: _regions.isEmpty ? null : _undo,
              icon: const Icon(Icons.undo)),
            IconButton(tooltip: '취소한 영역 복원', onPressed: _removed == null ? null : _redo,
              icon: const Icon(Icons.redo)),
          ]),
          if (_regions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _busy ? null : () => setState(() {
                  _regions.clear();
                  _removed = null;
                  _output = null;
                }),
                icon: const Icon(Icons.layers_clear),
                label: const Text('영역 모두 지우기'),
              )),
          ],
        ])),
        const SizedBox(height: 14),
        const StudioSectionTitle(title: '가리기 효과'),
        StudioCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final pair in [
              (PrivacyEffect.mosaic, '모자이크'),
              (PrivacyEffect.blur, '흐림'),
              (PrivacyEffect.solid, '검정 가림'),
            ])
              ChoiceChip(
                label: Text(pair.$2),
                selected: _effect == pair.$1,
                onSelected: _busy ? null : (_) => setState(() => _effect = pair.$1),
              ),
          ]),
          const SizedBox(height: 10),
          if (_effect != PrivacyEffect.solid) ...[
            Text('효과 강도: ' + _strength.toString()),
            Slider(min: 8, max: 64, divisions: 14, value: _strength.toDouble(),
              onChanged: _busy ? null : (value) => setState(() => _strength = value.round())),
          ],
          FilledButton.icon(
            key: const Key('mask-export'),
            onPressed: _busy || _regions.isEmpty ? null : _export,
            icon: const Icon(Icons.auto_fix_high_outlined),
            label: Text(_busy ? '사진 처리 중...' : '가리기 적용'),
          ),
        ])),
        if (_output != null) ...[
          const SizedBox(height: 14),
          StudioSectionTitle(title: '결과 미리보기',
            subtitle: '개인정보가 전부 가려졌는지 확인하세요.'),
          StudioCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Image.memory(_output!, fit: BoxFit.contain),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('mask-share'),
              onPressed: _share,
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('사진 공유·저장'),
            ),
          ])),
        ],
        const SizedBox(height: 14),
        StudioNotice(message: '얼굴 ' + _detectedFaces.toString() +
          '개 · 문자 ' + _detectedText.toString() +
          '개 감지. 자동 인식은 누락될 수 있으므로 공유 전에 반드시 직접 확인하세요.'),
      ] else
        const StudioNotice(message: '갤러리에서 사진을 고른 다음 드래그로 영역을 지정하세요. 원본 사진은 변경하지 않습니다.'),
      if (_notice != null) ...[
        const SizedBox(height: 12),
        StudioNotice(message: _notice!, icon: Icons.info_outline),
      ],
      const SizedBox(height: 12),
      const StudioNotice(message: '사진은 기기에서만 처리되며, 저장된 JPEG에는 원본 GPS·EXIF 정보가 포함되지 않습니다. 차량번호는 문자 감지로 후보를 찾지만 전용 차량번호 인식 기능은 아닙니다.'),
    ]),
  );
}

class _PrivacyOverlay extends CustomPainter {
  const _PrivacyOverlay(this.regions, this.drag);
  final List<PrivacyRegion> regions;
  final Rect? drag;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = const Color(0xFFFF5D61)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = const Color(0x55FF5D61);
    for (final item in regions) {
      final rect = Rect.fromLTRB(
        item.left * size.width, item.top * size.height,
        item.right * size.width, item.bottom * size.height,
      );
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, outline);
    }
    if (drag != null) {
      canvas.drawRect(drag!, fill);
      canvas.drawRect(drag!, outline);
    }
  }

  @override
  bool shouldRepaint(covariant _PrivacyOverlay old) => true;
}
