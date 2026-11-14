import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_core/app_core.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const StudioApp(
    title: '픽셀 슬림', accent: Color(0xFF38CAB4), home: OptimizerPage());
}

class OptimizerPage extends StatefulWidget {
  const OptimizerPage({super.key});
  @override
  State<OptimizerPage> createState() => _OptimizerPageState();
}

class _OptimizerPageState extends State<OptimizerPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _picked;
  XFile? _video;
  File? _result;
  int _originalSize = 0, _newSize = 0;
  double _quality = 75;
  bool _busy = false;
  String? _error;

  Future<void> _select() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final size = await file.length();
      if (!mounted) return;
      setState(() {
        _picked = file; _result = null;
        _originalSize = size; _newSize = 0; _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '사진 선택 실패: $e');
    }
  }

  Future<void> _compress() async {
    final selected = _picked;
    if (selected == null || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final data = await selected.readAsBytes();
      final bytes = await FlutterImageCompress.compressWithList(
        data, quality: _quality.round(), format: CompressFormat.jpeg,
        minWidth: 1280, minHeight: 1280);
      if (bytes.isEmpty) throw StateError('압축 결과가 비어 있습니다');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pixel_slim_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      setState(() { _result = file; _newSize = bytes.length; });
    } catch (e) {
      if (mounted) setState(() => _error = '압축 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null && mounted) setState(() => _video = file);
    } catch (e) {
      if (mounted) setState(() => _error = '동영상 선택 실패: $e');
    }
  }

  String _size(int size) => size >= 1048576
    ? '${(size / 1048576).toStringAsFixed(2)} MB'
    : '${(size / 1024).toStringAsFixed(1)} KB';

  @override
  Widget build(BuildContext context) => StudioScreen(
    title: '픽셀 슬림',
    subtitle: '사진은 휴대폰에서 압축합니다. 서버 업로드는 하지 않습니다.',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      StudioCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.image_outlined), const SizedBox(width: 8),
          Text('이미지 압축', style: Theme.of(context).textTheme.titleLarge),
        ]),
        const SizedBox(height: 16),
        if (_picked != null) ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(_picked!.path), height: 200, fit: BoxFit.contain)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _select,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(_picked == null ? '사진 선택' : '다른 사진 선택')),
        const SizedBox(height: 8),
        Text('압축 품질 ${_quality.round()}%'),
        Slider(min: 30, max: 95, divisions: 13, value: _quality,
          onChanged: _busy ? null : (v) => setState(() => _quality = v)),
        FilledButton.icon(
          onPressed: _picked == null || _busy ? null : _compress,
          icon: _busy ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.compress),
          label: const Text('사진 압축하기')),
        if (_picked != null)
          Padding(padding: const EdgeInsets.only(top: 12),
            child: Text('원본: ${_size(_originalSize)}${_result == null ? '' : ' → 결과: ${_size(_newSize)}'}')),
        if (_result != null) ...[
          const SizedBox(height: 8),
          Text(_newSize < _originalSize
            ? '약 ${((1 - _newSize / _originalSize) * 100).toStringAsFixed(1)}% 감소'
            : '이 사진에서는 용량이 줄지 않았습니다.'),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.share), label: const Text('압축 파일 공유/저장'),
            onPressed: () => Share.shareXFiles([XFile(_result!.path)], text: '픽셀 슬림 이미지')),
        ],
      ])),
      const SizedBox(height: 12),
      StudioCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.movie_outlined), const SizedBox(width: 8),
          Text('동영상', style: Theme.of(context).textTheme.titleLarge),
        ]),
        const SizedBox(height: 10),
        const Text('동영상 선택을 지원합니다. 영상 재인코딩은 다음 개발 단계에서 추가됩니다.'),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickVideo,
          icon: const Icon(Icons.video_library), label: const Text('동영상 선택')),
        if (_video != null) FutureBuilder<int>(
          future: _video!.length(),
          builder: (context, snapshot) => Text(
            '${_video!.name} · ${snapshot.hasData ? _size(snapshot.data!) : '크기 확인 중'}')),
      ])),
      if (_error != null) Padding(padding: const EdgeInsets.all(12),
        child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent))),
    ]),
  );
}
