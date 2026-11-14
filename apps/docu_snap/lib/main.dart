import 'dart:io';
import 'dart:typed_data';

import 'package:app_core/app_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const StudioApp(
      title: '도큐 스냅', accent: Color(0xFFFFB65E), home: DocumentPage());
}

Uint8List enhanceScan(Uint8List data) {
  final input = img.decodeImage(data);
  if (input == null) throw StateError('지원하지 않는 이미지 형식');
  final gray = img.grayscale(input);
  final processed = img.adjustColor(gray, contrast: 1.28, brightness: 1.04);
  return img.encodeJpg(processed, quality: 86);
}

class DocumentPage extends StatefulWidget {
  const DocumentPage({super.key});
  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _fileName = TextEditingController(text: '내_스캔문서');
  List<XFile> _photos = [];
  int _selectedIndex = 0;
  bool _busy = false, _scanMode = true, _korean = true;
  String? _error, _recognizedText;
  File? _lastPdf;

  @override
  void dispose() {
    _fileName.dispose();
    super.dispose();
  }

  Future<void> _gallery() async {
    if (_busy) return;
    try {
      final files = await _picker.pickMultiImage(limit: 10);
      if (!mounted || files.isEmpty) return;
      setState(() {
        _photos = [..._photos, ...files].take(10).toList();
        _selectedIndex = 0;
        _recognizedText = null;
        _lastPdf = null;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = '사진을 가져올 수 없습니다: $error');
    }
  }

  Future<void> _camera() async {
    if (_busy || _photos.length >= 10) return;
    try {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (!mounted || file == null) return;
      setState(() {
        _photos.add(file);
        _selectedIndex = _photos.length - 1;
        _recognizedText = null;
        _lastPdf = null;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = '촬영 실패: $error');
    }
  }

  void _remove(int index) {
    if (_busy) return;
    setState(() {
      _photos.removeAt(index);
      _selectedIndex = _photos.isEmpty ? 0 : _selectedIndex.clamp(0, _photos.length - 1).toInt();
      _recognizedText = null;
      _lastPdf = null;
    });
  }

  void _move(int index, int change) {
    final next = index + change;
    if (_busy || next < 0 || next >= _photos.length) return;
    setState(() {
      final item = _photos.removeAt(index);
      _photos.insert(next, item);
      _selectedIndex = next;
      _lastPdf = null;
    });
  }

  Future<void> _recognize() async {
    if (_busy || _photos.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _recognizedText = null;
    });
    final recognizer = TextRecognizer(
      script: _korean ? TextRecognitionScript.korean : TextRecognitionScript.latin,
    );
    try {
      final path = _photos[_selectedIndex].path;
      final recognized = await recognizer.processImage(InputImage.fromFilePath(path));
      if (mounted) setState(() => _recognizedText = recognized.text.trim());
    } catch (error) {
      if (mounted) setState(() => _error = '글자를 인식하지 못했습니다: $error');
    } finally {
      await recognizer.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPdf() async {
    if (_busy || _photos.isEmpty) return;
    setState(() {
      _busy = true;
      _lastPdf = null;
      _error = null;
    });
    try {
      final document = pw.Document(compress: true);
      for (final photo in _photos) {
        final source = await photo.readAsBytes();
        final bytes = _scanMode ? await compute(enhanceScan, source) : source;
        final image = pw.MemoryImage(bytes);
        document.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (context) => pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain)),
        ));
      }
      final dir = await getTemporaryDirectory();
      final raw = _fileName.text.trim();
      final clean = raw.isEmpty ? '내_스캔문서' :
          raw.replaceAll(RegExp(r'[\/:*?"<>|]'), '_');
      final path = dir.path + '/' + clean + '_' +
          DateTime.now().millisecondsSinceEpoch.toString() + '.pdf';
      final file = File(path);
      await file.writeAsBytes(await document.save());
      if (!mounted) return;
      setState(() => _lastPdf = file);
    } catch (error) {
      if (mounted) setState(() => _error = 'PDF 생성 실패: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() async {
    final file = _lastPdf;
    if (file == null) return;
    try {
      await Share.shareXFiles([XFile(file.path)], text: '도큐 스냅 PDF');
    } catch (error) {
      if (mounted) setState(() => _error = 'PDF 공유 실패: $error');
    }
  }

  @override
  Widget build(BuildContext context) => StudioScreen(
    title: '도큐 스냅',
    subtitle: '문서를 찍고, 정리하고, PDF로 내보내세요.',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const StudioHero(
        icon: Icons.document_scanner_outlined,
        title: '휴대폰으로 간편하게 스캔',
        description: '사진 여러 장을 정리하고 A4 PDF로 만들어 보세요.',
      ),
      const SizedBox(height: 16),
      StudioSectionTitle(
        title: '스캔할 사진',
        subtitle: '최대 10장 · 순서 변경 지원',
        trailing: Text(_photos.length.toString() + ' / 10'),
      ),
      StudioCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _gallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('갤러리에서 추가'),
            ),
            OutlinedButton.icon(
              onPressed: _busy || _photos.length >= 10 ? null : _camera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('문서 촬영'),
            ),
            if (_photos.isNotEmpty)
              TextButton.icon(
                onPressed: _busy ? null : () => setState(() {
                  _photos.clear();
                  _recognizedText = null;
                  _lastPdf = null;
                }),
                icon: const Icon(Icons.delete_outline),
                label: const Text('전체 비우기'),
              ),
          ]),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 680 ? 4 :
                  constraints.maxWidth >= 420 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _photos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns, crossAxisSpacing: 8,
                  mainAxisSpacing: 8, childAspectRatio: .72,
                ),
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedIndex == index
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF3B465B),
                      width: _selectedIndex == index ? 2 : 1,
                    ),
                  ),
                  child: Column(children: [
                    Expanded(child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.file(File(_photos[index].path), fit: BoxFit.cover),
                          Positioned(left: 4, top: 4, child: CircleAvatar(
                            radius: 12,
                            child: Text((index + 1).toString(),
                              style: const TextStyle(fontSize: 11)),
                          )),
                        ]),
                      ),
                    )),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: '앞으로 이동',
                        icon: const Icon(Icons.chevron_left, size: 19),
                        onPressed: index == 0 || _busy ? null : () => _move(index, -1),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: '삭제',
                        icon: const Icon(Icons.close, size: 17),
                        onPressed: _busy ? null : () => _remove(index),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: '뒤로 이동',
                        icon: const Icon(Icons.chevron_right, size: 19),
                        onPressed: index == _photos.length - 1 || _busy
                            ? null : () => _move(index, 1),
                      ),
                    ]),
                  ]),
                ),
              );
            }),
          ],
        ],
      )),
      const SizedBox(height: 16),
      const StudioSectionTitle(title: 'PDF 만들기'),
      StudioCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _fileName,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: '파일 이름',
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('선명한 흑백 문서'),
            subtitle: const Text('사진을 회색조·대비 보정하여 PDF에 넣습니다.'),
            value: _scanMode,
            onChanged: _busy ? null : (value) => setState(() => _scanMode = value),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('pdf-create'),
            onPressed: _photos.isEmpty || _busy ? null : _createPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_busy ? '처리 중...' : 'PDF 생성하기'),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_lastPdf != null) ...[
            const SizedBox(height: 12),
            Text('완료 · ' + _photos.length.toString() + '페이지 · ' +
                (_lastPdf!.lengthSync() / 1024).toStringAsFixed(1) + ' KB'),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _sharePdf,
              icon: const Icon(Icons.share_outlined),
              label: const Text('PDF 공유·저장'),
            ),
          ],
        ],
      )),
      const SizedBox(height: 16),
      const StudioSectionTitle(title: '글자 인식 (OCR)', subtitle: '선택한 사진 1장의 글자를 추출합니다.'),
      StudioCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, children: [
            ChoiceChip(
              label: const Text('한국어'),
              selected: _korean,
              onSelected: _busy ? null : (_) => setState(() => _korean = true),
            ),
            ChoiceChip(
              label: const Text('영어'),
              selected: !_korean,
              onSelected: _busy ? null : (_) => setState(() => _korean = false),
            ),
          ]),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: _photos.isEmpty || _busy ? null : _recognize,
            icon: const Icon(Icons.text_snippet_outlined),
            label: Text((_selectedIndex + 1).toString() + '번 사진 글자 인식'),
          ),
          if (_recognizedText != null) ...[
            const SizedBox(height: 12),
            SelectableText(_recognizedText!.isEmpty
                ? '인식된 글자가 없습니다. 글자가 선명한 사진으로 다시 시도해 주세요.'
                : _recognizedText!),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _recognizedText!.isEmpty ? null : () async {
                await Clipboard.setData(ClipboardData(text: _recognizedText!));
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('인식한 글자를 복사했습니다.')));
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('텍스트 복사'),
            ),
          ],
        ],
      )),
      if (_error != null) ...[
        const SizedBox(height: 14),
        StudioNotice(message: _error!, icon: Icons.error_outline),
      ],
      const SizedBox(height: 14),
      const StudioNotice(message: '이미지와 인식 결과는 이 기기에서 처리됩니다. 자동 테두리 검출·원근 보정·기존 PDF 병합은 아직 지원하지 않습니다.'),
    ]),
  );
}
