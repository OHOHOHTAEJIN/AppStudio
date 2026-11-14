// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:async';
import 'dart:math';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const StudioApp(
      title: '펄스 퍼즐', accent: Color(0xFF9A82FF), home: PuzzlePage());
}

enum PuzzleMode {
  sprint('30초 스피드', 30, 0),
  classic('60초 챌린지', 60, 0),
  zen('20단계 집중', 0, 20);

  const PuzzleMode(this.label, this.seconds, this.goal);
  final String label;
  final int seconds;
  final int goal;
}

enum PuzzleLevel {
  easy('쉬움', 9, 6),
  normal('보통', 12, 9),
  hard('어려움', 16, 15);

  const PuzzleLevel(this.label, this.cells, this.maxNumber);
  final String label;
  final int cells;
  final int maxNumber;
}

List<int> createPuzzleBoard(Random random, PuzzleLevel level, int target) {
  assert(target >= 1 && target <= level.maxNumber);
  final board = List<int>.generate(level.cells, (_) {
    int number;
    do {
      number = random.nextInt(level.maxNumber) + 1;
    } while (number == target);
    return number;
  });
  board[random.nextInt(board.length)] = target;
  return board;
}

int puzzlePoints(int combo) => 10 + (combo ~/ 3) * 2;

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key});
  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  final _random = Random();
  Timer? _timer;
  PuzzleMode _mode = PuzzleMode.classic;
  PuzzleLevel _level = PuzzleLevel.normal;
  List<int> _board = [];
  int _target = 1, _score = 0, _best = 0, _seconds = 60;
  int _combo = 0, _longestCombo = 0, _rounds = 0;
  bool _playing = false, _paused = false, _finished = false;

  @override
  void initState() {
    super.initState();
    _newBoard();
    _loadBest();
  }

  String get _recordKey => 'puzzle_best_' + _mode.name + '_' + _level.name;

  Future<void> _loadBest() async {
    final key = _recordKey;
    final prefs = await SharedPreferences.getInstance();
    if (mounted && key == _recordKey) {
      setState(() => _best = prefs.getInt(key) ?? 0);
    }
  }

  void _newBoard() {
    _target = _random.nextInt(_level.maxNumber) + 1;
    _board = createPuzzleBoard(_random, _level, _target);
  }

  void _startClock() {
    _timer?.cancel();
    if (_mode.seconds == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_playing || _paused) return;
      if (_seconds <= 1) {
        _finish();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _score = 0;
      _combo = 0;
      _longestCombo = 0;
      _rounds = 0;
      _seconds = _mode.seconds;
      _playing = true;
      _paused = false;
      _finished = false;
      _newBoard();
    });
    _startClock();
  }

  void _pause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _timer?.cancel();
    } else {
      _startClock();
    }
  }

  Future<void> _finish() async {
    if (!_playing) return;
    _timer?.cancel();
    final key = _recordKey;
    final newBest = max(_score, _best);
    setState(() {
      _playing = false;
      _paused = false;
      _finished = true;
      _seconds = _mode.seconds == 0 ? 0 : max(0, _seconds);
      _best = newBest;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, newBest);
  }

  void _tap(int index) {
    if (!_playing || _paused) return;
    final correct = _board[index] == _target;
    if (correct) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
    setState(() {
      if (correct) {
        _combo++;
        _longestCombo = max(_longestCombo, _combo);
        _score += puzzlePoints(_combo);
        _rounds++;
        _newBoard();
      } else {
        _score = max(0, _score - 5);
        _combo = 0;
      }
    });
    if (correct && _mode.goal > 0 && _rounds >= _mode.goal) _finish();
  }

  void _changeMode(PuzzleMode mode) {
    if (_playing) return;
    setState(() {
      _mode = mode;
      _seconds = mode.seconds;
      _best = 0;
      _finished = false;
      _newBoard();
    });
    _loadBest();
  }

  void _changeLevel(PuzzleLevel level) {
    if (_playing) return;
    setState(() {
      _level = level;
      _best = 0;
      _finished = false;
      _newBoard();
    });
    _loadBest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StudioScreen(
    title: '펄스 퍼즐',
    subtitle: '숫자를 빠르게 찾아 점수와 최고 기록을 올려보세요.',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const StudioHero(
        icon: Icons.grid_view_rounded,
        title: '하루 1분 두뇌 워밍업',
        description: '숫자를 찾고, 연속 정답 콤보를 이어보세요.',
      ),
      const SizedBox(height: 16),
      AdaptiveStatGrid(children: [
        StatBox(label: '현재 점수', value: '$_score', icon: Icons.bolt),
        StatBox(label: '최고 점수', value: '$_best', icon: Icons.emoji_events_outlined),
        StatBox(
          label: _mode.seconds == 0 ? '진행 단계' : '남은 시간',
          value: _mode.seconds == 0 ? '$_rounds / ' + _mode.goal.toString() : '$_seconds초',
          icon: Icons.timer_outlined,
        ),
        StatBox(label: '현재 콤보', value: '$_combo회', icon: Icons.local_fire_department),
      ]),
      const SizedBox(height: 18),
      const StudioSectionTitle(title: '게임 설정', subtitle: '시작 전 모드와 난이도를 선택하세요.'),
      StudioCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('게임 모드', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: PuzzleMode.values.map((mode) => ChoiceChip(
              label: Text(mode.label),
              selected: _mode == mode,
              onSelected: _playing ? null : (_) => _changeMode(mode),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text('난이도', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: PuzzleLevel.values.map((level) => ChoiceChip(
              label: Text(level.label),
              selected: _level == level,
              onSelected: _playing ? null : (_) => _changeLevel(level),
            )).toList(),
          ),
        ],
      )),
      const SizedBox(height: 16),
      StudioCard(child: Column(children: [
        Text(
          _finished ? '게임 완료 · $_score점' :
          _paused ? '일시정지 중' : _playing ? '이 숫자를 찾아보세요' : '준비됐나요?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text('$_target', key: const Key('puzzle-target'),
          style: TextStyle(
            fontSize: 64, fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          )),
        Text(_finished ? '최대 콤보 $_longestCombo회 · 다시 도전해보세요' :
          _playing ? '정답 +10점 이상 · 오답 -5점' : '시작 버튼을 누르면 문제가 나타납니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFAAB6CC))),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 580 ? 5 :
              constraints.maxWidth >= 360 ? 4 : 3;
          return GridView.builder(
            key: const Key('puzzle-board'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _board.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 8, mainAxisSpacing: 8,
              childAspectRatio: 1.12,
            ),
            itemBuilder: (context, i) => FilledButton.tonal(
              key: Key('puzzle-cell-$i'),
              onPressed: _playing && !_paused ? () => _tap(i) : null,
              style: FilledButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(_board[i].toString(), style: const TextStyle(
                  fontSize: 27, fontWeight: FontWeight.w800)),
            ),
          );
        }),
      ])),
      const SizedBox(height: 14),
      if (!_playing)
        FilledButton.icon(
          key: const Key('puzzle-start'),
          onPressed: _start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(_finished ? '다시 도전하기' : '게임 시작'),
        )
      else
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _pause,
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
            label: Text(_paused ? '계속하기' : '일시정지'),
          )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(
            onPressed: _finish,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('게임 종료'),
          )),
        ]),
      const SizedBox(height: 14),
      const StudioNotice(message: '기록은 이 기기에만 저장됩니다. 게임 중에는 모드와 난이도를 바꿀 수 없습니다.'),
    ]),
  );
}
