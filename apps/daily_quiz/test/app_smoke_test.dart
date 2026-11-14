import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_quiz/main.dart';
import 'package:daily_quiz/questions.dart';

void main() {
  test('question bank is valid and daily questions are deterministic', () {
    expect(questionBank.length, greaterThanOrEqualTo(90));
    for (final item in questionBank) {
      expect(item.answers.length, 4);
      expect(item.correct, inInclusiveRange(0, 3));
      expect(item.answers.toSet().length, 4);
    }
    final now = DateTime(2026, 11, 14);
    final one = pickQuizQuestions(date: now, mode: QuizMode.daily);
    final two = pickQuizQuestions(date: now, mode: QuizMode.daily);
    expect(one.length, 10);
    expect(one.map((e) => e.prompt).toList(),
        two.map((e) => e.prompt).toList());
    final it = pickQuizQuestions(date: now, mode: QuizMode.practice,
        category: 'IT', seed: 4);
    expect(it.length, 10);
    expect(it.every((q) => q.category == 'IT'), isTrue);
  });

  testWidgets('quiz opens a question and displays feedback', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('quiz-start')));
    await tester.tap(find.byKey(const Key('quiz-start')));
    await tester.pump();
    expect(find.byKey(const Key('quiz-question')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('quiz-answer-0')));
    await tester.tap(find.byKey(const Key('quiz-answer-0')));
    await tester.pump();
    expect(find.byKey(const Key('quiz-next')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
