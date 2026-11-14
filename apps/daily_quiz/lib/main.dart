import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_core/app_core.dart';
import 'questions.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const StudioApp(
    title: '데일리 퀴즈', accent: Color(0xFFFF7BAA), home: QuizPage());
}
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override State<QuizPage> createState() => _QuizPageState();
}
class _QuizPageState extends State<QuizPage> {
  List<QuizQuestion> _today = [];
  int _index = 0, _correct = 0, _best = 0, _streak = 0;
  int? _selected;
  bool _started = false, _finished = false;

  @override
  void initState() {
    super.initState();
    _prepareDaily();
    _load();
  }

  String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void _prepareDaily() {
    final d = DateTime.now();
    final rng = Random(d.year * 10000 + d.month * 100 + d.day);
    _today = List<QuizQuestion>.from(questionBank)..shuffle(rng);
    _today = _today.take(10).toList();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _best = prefs.getInt('quiz_best') ?? 0;
      _streak = prefs.getInt('quiz_streak') ?? 0;
    });
  }

  void _start() => setState(() {
    _started = true; _finished = false; _index = 0;
    _correct = 0; _selected = null;
    _prepareDaily();
  });

  Future<void> _next() async {
    if (_selected == null) return;
    if (_selected == _today[_index].correct) _correct++;
    if (_index < _today.length - 1) {
      setState(() { _index++; _selected = null; });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final today = _day(DateTime.now());
    final last = prefs.getString('quiz_last_day');
    if (last != today) {
      final yesterday = _day(DateTime.now().subtract(const Duration(days: 1)));
      _streak = last == yesterday ? _streak + 1 : 1;
      await prefs.setString('quiz_last_day', today);
      await prefs.setInt('quiz_streak', _streak);
    }
    if (_correct > _best) {
      _best = _correct;
      await prefs.setInt('quiz_best', _best);
    }
    if (mounted) setState(() { _started = false; _finished = true; });
  }

  @override
  Widget build(BuildContext context) => StudioScreen(
    title: '데일리 퀴즈',
    subtitle: '매일 10문제! 과학 · 지리 · IT · 생활 상식',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AdaptiveStatGrid(children: [
        StatBox(label: '최고 정답 수', value: '$_best / 10'),
        StatBox(label: '연속 참여', value: '$_streak일'),
      ]),
      const SizedBox(height: 14),
      if (!_started)
        StudioCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.psychology_alt_outlined, size: 64),
          const SizedBox(height: 12),
          Text(_finished ? '오늘 결과: $_correct / 10' : '오늘의 10문제',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text('로그인 없이 바로 시작', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _start,
            child: Text(_finished ? '다시 풀기' : '퀴즈 시작')),
        ])),
      if (_started) ...[
        LinearProgressIndicator(value: (_index + 1) / 10),
        const SizedBox(height: 12),
        StudioCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${_index + 1} / 10 · ${_today[_index].category}'),
          const SizedBox(height: 14),
          Text(_today[_index].prompt, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: _selected == null ? () => setState(() => _selected = i) : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: _selected == null ? null :
                  i == _today[_index].correct ? Colors.green.withValues(alpha: .3) :
                  i == _selected ? Colors.red.withValues(alpha: .3) : null,
                padding: const EdgeInsets.all(14),
                alignment: Alignment.centerLeft),
              child: Text('${i + 1}. ${_today[_index].answers[i]}'),
            ),
          )),
          if (_selected != null)
            Text(_selected == _today[_index].correct ? '정답입니다!' :
              '정답: ${_today[_index].answers[_today[_index].correct]}'),
          const SizedBox(height: 8),
          FilledButton(onPressed: _selected == null ? null : _next,
            child: Text(_index == 9 ? '결과 보기' : '다음 문제')),
        ])),
      ],
    ]),
  );
}
