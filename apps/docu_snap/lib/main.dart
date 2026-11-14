import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_core/app_core.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const StudioApp(
    title: '도큐 스냅', accent: Color(0xFFFFB65E), home: DocumentPage());
}

class DocumentPage extends StatefulWidget {
  const DocumentPage({super.key});
  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _photos = [];
  bool _busy = false;
  String? _error;

  Future<void> _gallery() async {
    try {
      final files = await _picker.pickMultiImage(limit: 10);
      if (!mounted || files.isEmpty) return;
      setState(() { _photos = files.take(10).toList(); _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = '이미지 선택 실패: $e');
    }
  }

  Future<void> _camera() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (!mounted || file == null) return;
      setState(() {
        _photos = [..._photos, file].take(10).toList();
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '촬영 실패: $e');
    }
  }

  Future<void> _createPdf() async {
    if (_busy || _photos.isEmpty) return;
    setState(() { _busy = true; _error = null; });
    try {
      final doc = pw.Document(compress: true);
      for (final photo in _photos) {
        final bytes = await photo.readAsBytes();
        final image = pw.MemoryImage(bytes);
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(22),
          build: (context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain))));
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/docu_snap_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await doc.save());
      if (mounted) await Share.shareXFiles([XFile(file.path)], text: '도큐 스냅으로 만든 PDF');
    } catch (e) {
      if (mounted) setState(() => _error = 'PDF 생성 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => StudioScreen(
    title: '도큐 스냅',
    subtitle: '사진을 PDF로 변환 · 기기 내 처리 · 계정 불필요',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      StudioCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${_photos.length} / 10장 선택됨',
          style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('사진 순서대로 A4 PDF 페이지가 만들어집니다. 서버로 전송하지 않습니다.'),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _gallery,
            icon: const Icon(Icons.collections_outlined), label: const Text('갤러리 선택')),
          OutlinedButton.icon(
            onPressed: _busy || _photos.length >= 10 ? null : _camera,
            icon: const Icon(Icons.camera_alt_outlined), label: const Text('문서 촬영')),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _photos = []),
            child: const Text('비우기')),
        ]),
      ])),
      if (_photos.isNotEmpty) ...[
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) => GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: _photos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth >= 700 ? 5 :
              constraints.maxWidth >= 400 ? 3 : 2,
            crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .78),
          itemBuilder: (context, i) => Stack(children: [
            Positioned.fill(child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(_photos[i].path), fit: BoxFit.cover))),
            Positioned(top: 4, left: 4,
              child: CircleAvatar(radius: 13,
                child: Text('${i + 1}', style: const TextStyle(fontSize: 11)))),
            Positioned(top: 3, right: 3,
              child: IconButton.filledTonal(
                tooltip: '${i + 1}번 사진 제거',
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() => _photos.removeAt(i)))),
          ]),
        )),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _createPdf,
          icon: _busy ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.picture_as_pdf),
          label: Text(_busy ? 'PDF 생성 중' : 'PDF 생성 및 공유')),
      ],
      if (_error != null)
        Padding(padding: const EdgeInsets.all(12),
          child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent))),
      const SizedBox(height: 14),
      const Text('OCR·문서 자동 보정·기존 PDF 병합은 후속 개발 항목입니다.'),
    ]),
  );
}
