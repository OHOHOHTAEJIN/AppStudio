import 'dart:async';
import 'dart:io';
import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_compress_next/video_compress_next.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const StudioApp(
      title: '픽셀 슬림', accent: Color(0xFF38CAB4), home: OptimizerPage());
}

String formatMediaSize(int bytes) {
  if (bytes >= 1048576) return (bytes / 1048576).toStringAsFixed(2) + ' MB';
  if (bytes >= 1024) return (bytes / 1024).toStringAsFixed(1) + ' KB';
  return '$bytes B';
}

class OptimizerPage extends StatefulWidget {
  const OptimizerPage({super.key});
  @override
  State<OptimizerPage> createState() => _OptimizerPageState();
}

class _OptimizerPageState extends State<OptimizerPage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _photos = [];
  final List<File> _results = [];
  XFile? _video;
  File? _videoResult;
  CompressTask? _videoTask;
  StreamSubscription<double>? _videoListener;
  int _inputBytes = 0, _resultBytes = 0, _progressCount = 0;
  int _videoBytes = 0, _videoSide = 720, _photoSize = 1920;
  double _quality = 75, _videoProgress = 0;
  bool _busy = false, _cancelBatch = false, _videos = false;
  String? _error;

  @override
  void dispose() {
    _videoListener?.cancel();
    _videoTask?.cancel();
    super.dispose();
  }

  Future<void> _choosePhotos() async {
    try {
      final selected = await _picker.pickMultiImage(limit: 20);
      if (selected.isEmpty) return;
      var total = 0;
      for (final item in selected) {
        total += await item.length();
      }
      if (!mounted) return;
      setState(() {
        _photos = selected.take(20).toList();
        _inputBytes = total;
        _results.clear();
        _resultBytes = 0;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '사진 선택 실패: $e');
    }
  }

  Future<void> _compressPhotos() async {
    if (_busy || _photos.isEmpty) return;
    setState(() {
      _busy = true;
      _cancelBatch = false;
      _progressCount = 0;
      _resultBytes = 0;
      _results.clear();
      _error = null;
    });
    var failed = 0;
    try {
      final folder = await getTemporaryDirectory();
      for (var i = 0; i < _photos.length; i++) {
        if (_cancelBatch) break;
        try {
          final bytes = await _photos[i].readAsBytes();
          final output = await FlutterImageCompress.compressWithList(
            bytes, quality: _quality.round(),
            format: CompressFormat.jpeg,
            minWidth: _photoSize,
            minHeight: _photoSize,
          );
          if (output.isEmpty) throw StateError('이미지 변환 결과가 비어 있습니다');
          final file = File(folder.path + '/pixel_slim_' +
              DateTime.now().microsecondsSinceEpoch.toString() + '_$i.jpg');
          await file.writeAsBytes(output);
          if (!mounted) return;
          setState(() {
            _results.add(file);
            _resultBytes += output.length;
          });
        } catch (_) {
          failed++;
        } finally {
          if (mounted) setState(() => _progressCount = i + 1);
        }
      }
      if (mounted && failed > 0) {
        setState(() => _error = '사진 $failed장 처리가 실패했습니다.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = '압축 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseVideo() async {
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;
      final size = await file.length();
      if (!mounted) return;
      setState(() {
        _video = file;
        _videoBytes = size;
        _videoResult = null;
        _videoProgress = 0;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '영상 선택 실패: $e');
    }
  }

  Future<void> _compressVideo() async {
    if (_video == null || _busy) return;
    setState(() {
      _busy = true;
      _videoResult = null;
      _videoProgress = 0;
      _error = null;
    });
    try {
      final task = VideoCompressor.compress(
        _video!.path,
        options: CompressOptions(
          maxShortSide: _videoSide,
          codec: VideoCodec.h264,
          includeAudio: true,
        ),
      );
      _videoTask = task;
      _videoListener = task.progress.listen((value) {
        if (mounted) setState(() =>
            _videoProgress = value.clamp(0.0, 1.0).toDouble());
      });
      final info = await task.result;
      if (mounted) setState(() {
        _videoResult = File(info.path);
        _videoProgress = 1;
      });
    } on VideoCompressException catch (e) {
      if (mounted) setState(() =>
        _error = e.error == VideoCompressError.cancelled ?
          '동영상 압축이 취소됐습니다.' : '동영상 압축 실패: $e');
    } catch (e) {
      if (mounted) setState(() => _error = '동영상 압축 오류: $e');
    } finally {
      await _videoListener?.cancel();
      _videoListener = null;
      _videoTask = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => StudioScreen(
    title: '픽셀 슬림',
    subtitle: '사진·동영상을 휴대폰에서 압축합니다. 서버 업로드는 하지 않습니다.',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const StudioHero(
        icon: Icons.auto_awesome_motion,
        title: '미디어 용량 줄이기',
        description: '여러 장의 사진과 긴 영상도 간단하게 최적화하세요.',
      ),
      const SizedBox(height: 16),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, icon: Icon(Icons.image_outlined), label: Text('사진')),
          ButtonSegment(value: true, icon: Icon(Icons.movie_outlined), label: Text('동영상')),
        ],
        selected: {_videos},
        onSelectionChanged: _busy ? null : (value) =>
          setState(() { _videos = value.first; _error = null; }),
      ),
      const SizedBox(height: 16),
      if (!_videos) ...[
        const StudioSectionTitle(title: '사진 일괄 압축', subtitle: '한 번에 최대 20장'),
        StudioCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_photos.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(_photos.first.path), height: 185, fit: BoxFit.contain)),
            const SizedBox(height: 10),
            Text('선택한 사진 ' + _photos.length.toString() + '장 · ' +
                formatMediaSize(_inputBytes)),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _choosePhotos,
            icon: const Icon(Icons.collections_outlined),
            label: Text(_photos.isEmpty ? '사진 선택' : '다른 사진 선택'),
          ),
          const SizedBox(height: 14),
          Text('압축 화질 ' + _quality.round().toString() + '%'),
          Slider(
            min: 30, max: 95, divisions: 13, value: _quality,
            onChanged: _busy ? null : (v) => setState(() => _quality = v),
          ),
          DropdownButtonFormField<int>(
            initialValue: _photoSize,
            decoration: const InputDecoration(labelText: '최대 사진 크기'),
            items: const [
              DropdownMenuItem(value: 1280, child: Text('작게 · 1280px')),
              DropdownMenuItem(value: 1920, child: Text('권장 · 1920px')),
              DropdownMenuItem(value: 4096, child: Text('고화질 · 4096px')),
            ],
            onChanged: _busy ? null : (v) {
              if (v != null) setState(() => _photoSize = v);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _photos.isEmpty || _busy ? null : _compressPhotos,
            icon: const Icon(Icons.compress),
            label: Text(_busy ? '처리 중...' : '사진 압축하기'),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _photos.isEmpty ? null :
                _progressCount / _photos.length),
            Text('$_progressCount / ' + _photos.length.toString() + '장 처리'),
            TextButton(
              onPressed: () => _cancelBatch = true,
              child: const Text('남은 사진 취소'),
            ),
          ],
        ])),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 14),
          StudioCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('완료 ' + _results.length.toString() + '장',
              style: Theme.of(context).textTheme.titleMedium),
            Text('원본 ' + formatMediaSize(_inputBytes) +
                ' → 결과 ' + formatMediaSize(_resultBytes)),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => Share.shareXFiles(
                  _results.map((f) => XFile(f.path)).toList(),
                  text: '픽셀 슬림 압축 파일'),
              icon: const Icon(Icons.share),
              label: const Text('파일 공유·저장'),
            ),
          ])),
        ],
      ] else ...[
        const StudioSectionTitle(title: '동영상 압축', subtitle: 'H.264 MP4 변환'),
        StudioCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _chooseVideo,
            icon: const Icon(Icons.video_library),
            label: const Text('동영상 선택'),
          ),
          if (_video != null) ...[
            const SizedBox(height: 10),
            Text(_video!.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('원본 용량 ' + formatMediaSize(_videoBytes)),
          ],
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: _videoSide,
            decoration: const InputDecoration(labelText: '출력 화질'),
            items: const [
              DropdownMenuItem(value: 480, child: Text('작게 · 480p')),
              DropdownMenuItem(value: 720, child: Text('권장 · 720p')),
              DropdownMenuItem(value: 1080, child: Text('고화질 · 1080p')),
            ],
            onChanged: _busy ? null : (v) {
              if (v != null) setState(() => _videoSide = v);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _video == null || _busy ? null : _compressVideo,
            icon: const Icon(Icons.movie_filter),
            label: Text(_busy ? '압축 중...' : '동영상 압축하기'),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _videoProgress),
            Text('진행률 ' + (_videoProgress * 100).round().toString() + '%'),
            TextButton(
              onPressed: () => _videoTask?.cancel(),
              child: const Text('압축 취소'),
            ),
          ],
          if (_videoResult != null) ...[
            const SizedBox(height: 12),
            Text('압축 완료 · ' + formatMediaSize(_videoResult!.lengthSync())),
            FilledButton.tonalIcon(
              onPressed: () => Share.shareXFiles(
                  [XFile(_videoResult!.path)], text: '픽셀 슬림 동영상'),
              icon: const Icon(Icons.share_outlined),
              label: const Text('압축 영상 공유·저장'),
            ),
          ],
        ])),
        const SizedBox(height: 12),
        const StudioNotice(message: '원본 동영상은 삭제하지 않습니다. 일부 기기와 코덱에서는 압축이 지원되지 않을 수 있습니다.'),
      ],
      if (_error != null) ...[
        const SizedBox(height: 12),
        StudioNotice(message: _error!, icon: Icons.error_outline),
      ],
      const SizedBox(height: 16),
      const StudioNotice(message: '변환 파일은 임시 공간에 저장됩니다. 공유·저장 버튼으로 중요한 파일을 보관하세요.'),
    ]),
  );
}
