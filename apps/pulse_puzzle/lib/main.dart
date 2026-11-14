import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_core/app_core.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const StudioApp(
    title: '펄스 퍼즐', accent: Color(0xFF9A82FF), home: PuzzlePage());
}

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key});
  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  final Random _rng = Random();
  Timer? _clock;
  List<int> _board = [];
  int _target = 1, _score = 0, _best = 0, _seconds = 60, _combo = 0;
  bool _playing = false, _finished = false;

  @override
  void initState() {
    super.initState();
    _newBoard();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _best = prefs.getInt('puzzle_best') ?? 0);
  }

  void _newBoard() {
    _target = _rng.nextInt(9) + 1;
    _board = List.generate(12, (_) {
      int n;
      do { n = _rng.nextInt(9) + 1; } while (n == _target);
      return n;
    });
    _board[_rng.nextInt(_board.length)] = _target;
  }

  void _start() {
    _clock?.cancel();
    setState(() {
      _score = 0; _seconds = 60; _combo = 0;
      _playing = true; _finished = false; _newBoard();
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_seconds <= 1) { _finish(); }
      else { setState(() => _seconds--); }
    });
  }

  Future<void> _finish() async {
    _clock?.cancel();
    if (!mounted) return;
    setState(() {
      _playing = false; _finished = true; _seconds = 0;
      if (_score > _best) _best = _score;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('puzzle_best', _best);
  }

  void _tap(int index) {
    if (!_playing) return;
    setState(() {
      if (_board[index] == _target) {
        _combo++;
        _score += 10 + (_combo ~/ 3) * 2;
        _newBoard();
      } else {
        _score = max(0, _score - 5);
        _combo = 0;
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StudioScreen(
    title: '펄스 퍼즐',
    subtitle: '같은 숫자를 빠르게 찾아보세요 · 60초 챌린지',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AdaptiveStatGrid(children: [
        StatBox(label: '점수', value: '$_score'),
        StatBox(label: '최고 기록', value: '$_best'),
        StatBox(label: '남은 시간', value: '$_seconds초'),
        StatBox(label: '연속 성공', value: '$_combo'),
      ]),
      const SizedBox(height: 16),
      StudioCard(child: Column(children: [
        const Text('찾아야 할 숫자'),
        Text('$_target', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900,
          color: Color(0xFFBDADFF))),
        Text(_finished ? '게임 종료! 다시 도전해보세요' :
          _playing ? '정답 10점 · 오답 -5점' : '시작 버튼을 눌러주세요'),
      ])),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final count = constraints.maxWidth >= 680 ? 6 :
          constraints.maxWidth >= 440 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: _board.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count, crossAxisSpacing: 8,
            mainAxisSpacing: 8, childAspectRatio: 1.12),
          itemBuilder: (context, i) => FilledButton.tonal(
            onPressed: _playing ? () => _tap(i) : null,
            style: FilledButton.styleFrom(padding: EdgeInsets.zero),
            child: Text('${_board[i]}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          ),
        );
      }),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _playing ? null : _start,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(_finished ? '다시 도전하기' : '게임 시작')),
    ]),
  );
}
