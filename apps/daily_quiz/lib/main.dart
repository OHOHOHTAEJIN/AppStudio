import 'dart:math';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'questions.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const StudioApp(
      title: '데일리 퀴즈', accent: Color(0xFFFF7BAA), home: QuizPage());
}

enum QuizMode {
  daily('오늘의 10문제'),
  practice('분야별 연습');

  const QuizMode(this.label);
  final String label;
}

const quizCategories = ['전체', '과학', '지리', 'IT', '생활'];

List<QuizQuestion> pickQuizQuestions({
  required DateTime date,
  required QuizMode mode,
  String category = '전체',
  int? seed,
}) {
  final pool = questionBank.where((q) =>
    mode == QuizMode.daily || category == '전체' || q.category == category).toList();
  final rng = Random(seed ?? (mode == QuizMode.daily
    ? date.year * 10000 + date.month * 100 + date.day
    : DateTime.now().microsecondsSinceEpoch));
  pool.shuffle(rng);
  return pool.take(10).toList();
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<QuizQuestion> _questions = [];
  QuizMode _mode = QuizMode.daily;
  String _category = '전체';
  int _index = 0, _correct = 0, _best = 0, _streak = 0;
  int? _selected;
  bool _started = false, _finished = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _prepare();
  }

  String _day(DateTime date) =>
      date.year.toString() + '-' + date.month.toString() + '-' + date.day.toString();

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _best = prefs.getInt('quiz_best') ?? 0;
      _streak = prefs.getInt('quiz_streak') ?? 0;
    });
  }

  void _prepare() {
    _questions = pickQuizQuestions(
      date: DateTime.now(),
      mode: _mode,
      category: _category,
    );
  }

  void _start() {
    setState(() {
      _started = true;
      _finished = false;
      _index = 0;
      _correct = 0;
      _selected = null;
      _prepare();
    });
  }

  void _select(int index) {
    if (!_started || _selected != null) return;
    setState(() => _selected = index);
  }

  Future<void> _next() async {
    if (_selected == null || !_started) return;
    if (_selected == _questions[_index].correct) _correct++;
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
      });
      return;
    }
    if (_mode == QuizMode.daily) {
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
    }
    if (mounted) setState(() {
      _started = false;
      _finished = true;
    });
  }

  void _chooseMode(QuizMode mode) {
    if (_started) return;
    setState(() {
      _mode = mode;
      _finished = false;
      _prepare();
    });
  }

  void _chooseCategory(String category) {
    if (_started) return;
    setState(() {
      _category = category;
      _finished = false;
      _prepare();
    });
  }

  Widget _answerButton(int index, QuizQuestion question) {
    final answered = _selected != null;
    final correct = question.correct == index;
    final chosen = _selected == index;
    final color = correct && answered
        ? const Color(0xFF1D664C)
        : chosen && answered ? const Color(0xFF74394C) : null;
    return Semantics(
      label: '선택지 ' + (index + 1).toString() + ', ' + question.answers[index],
      button: true,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          key: Key('quiz-answer-$index'),
          onPressed: answered ? null : () => _select(index),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            disabledForegroundColor: Colors.white,
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            minimumSize: const Size(0, 54),
          ),
          child: Row(children: [
            Text(String.fromCharCode(65 + index),
                style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 14),
            Expanded(child: Text(question.answers[index],
                style: const TextStyle(fontSize: 15))),
            if (answered && correct)
              const Icon(Icons.check_circle, color: Color(0xFF70EBB6)),
            if (answered && chosen && !correct)
              const Icon(Icons.close, color: Color(0xFFFF93A6)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StudioScreen(
    title: '데일리 퀴즈',
    subtitle: '부담 없는 10문제. 매일 조금씩 똑똑해지는 시간.',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const StudioHero(
        icon: Icons.psychology_alt_rounded,
        title: '가볍게 풀고 실력을 쌓아요',
        description: '오늘의 퀴즈 또는 원하는 분야를 골라 연습하세요.',
      ),
      const SizedBox(height: 16),
      AdaptiveStatGrid(children: [
        StatBox(label: '오늘의 최고 기록', value: '$_best / 10',
            icon: Icons.emoji_events_outlined),
        StatBox(label: '연속 참여', value: '$_streak일',
            icon: Icons.calendar_today_outlined),
      ]),
      const SizedBox(height: 16),
      if (!_started) ...[
        const StudioSectionTitle(title: '퀴즈 선택', subtitle: '오늘의 퀴즈는 하루에 한 번만 출석 기록됩니다.'),
        StudioCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(spacing: 8, runSpacing: 8,
              children: QuizMode.values.map((mode) => ChoiceChip(
                label: Text(mode.label),
                selected: _mode == mode,
                onSelected: (_) => _chooseMode(mode),
              )).toList(),
            ),
            if (_mode == QuizMode.practice) ...[
              const SizedBox(height: 16),
              const Text('연습할 분야'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8,
                children: quizCategories.map((cat) => ChoiceChip(
                  label: Text(cat),
                  selected: _category == cat,
                  onSelected: (_) => _chooseCategory(cat),
                )).toList(),
              ),
            ],
            const SizedBox(height: 18),
            Text(_finished
                ? '이번 결과: $_correct / 10'
                : _mode == QuizMode.daily ? '오늘의 10문제' : '10문제 연습',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(_finished
              ? '수고했어요! 다른 분야에도 도전해보세요.'
              : '총 ' + questionBank.length.toString() + '문제에서 출제됩니다.',
              style: const TextStyle(color: Color(0xFFAAB6CC))),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('quiz-start'),
              onPressed: _start,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(_finished ? '다시 풀기' : '퀴즈 시작'),
            ),
          ],
        )),
      ],
      if (_started) ...[
        StudioSectionTitle(
          title: '문제 ' + (_index + 1).toString() + ' / ' + _questions.length.toString(),
          subtitle: _questions[_index].category + ' · 현재 정답 $_correct개',
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: (_index + 1) / _questions.length,
          ),
        ),
        const SizedBox(height: 14),
        StudioCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_questions[_index].prompt,
                key: const Key('quiz-question'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, height: 1.45)),
            const SizedBox(height: 20),
            for (var i = 0; i < 4; i++) ...[
              _answerButton(i, _questions[_index]),
              const SizedBox(height: 9),
            ],
            if (_selected != null) ...[
              const SizedBox(height: 12),
              StudioNotice(
                icon: _selected == _questions[_index].correct
                    ? Icons.check_circle_outline : Icons.lightbulb_outline,
                message: (_selected == _questions[_index].correct
                    ? '정답입니다! ' : '정답: ' +
                    _questions[_index].answers[_questions[_index].correct] + '. ') +
                    (_questions[_index].explanation.isEmpty
                        ? '다음 문제로 넘어가세요.' : _questions[_index].explanation),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('quiz-next'),
              onPressed: _selected == null ? null : _next,
              child: Text(_index == _questions.length - 1 ? '결과 보기' : '다음 문제'),
            ),
          ],
        )),
      ],
      const SizedBox(height: 14),
      const StudioNotice(
        message: '문제와 기록은 기기에 보관됩니다. 온라인 로그인이나 계정이 필요하지 않습니다.',
      ),
    ]),
  );
}
