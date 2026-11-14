import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_pay/main.dart';
import 'package:shift_pay/pay_engine.dart';

void main() {
  test('day shift with 1 hour break yields 8 paid hours', () {
    final shift = WorkShift(
      id: '1',
      start: DateTime(2026, 11, 14, 9),
      end: DateTime(2026, 11, 14, 18),
      breakMinutes: 60,
    );
    final result = calculateShiftPay(shift, hourlyRate: 10320);
    expect(result.paidMinutes, 480);
    expect(result.baseKrw, 82560);
    expect(result.nightMinutes, 0);
    expect(result.overtimeExtraKrw, 0);
  });

  test('night shift with 1 hour break, premiums only when enabled', () {
    final shift = WorkShift(
      id: '2',
      start: DateTime(2026, 11, 14, 22),
      end: DateTime(2026, 11, 15, 6),
      breakMinutes: 60,
    );
    expect(shift.paidMinutes, 420);
    expect(shift.estimatedNightMinutes, 420);
    final basic = calculateShiftPay(shift, hourlyRate: 10320);
    final premium = calculateShiftPay(shift,
        hourlyRate: 10320, applyPremiums: true);
    expect(basic.totalKrw, 72240);
    expect(premium.nightExtraKrw, 36120);
    expect(premium.totalKrw, 108360);
  });

  test('records roundtrip and CSV encode', () {
    final sample = WorkShift(
      id: '3', start: DateTime(2026, 11, 14, 8),
      end: DateTime(2026, 11, 14, 17), breakMinutes: 60, note: '오전조',
    );
    final restored = WorkShift.decodeAll(WorkShift.encodeAll([sample]));
    expect(restored.single.start, sample.start);
    expect(restored.single.note, '오전조');
    expect(csvForMonth(restored, 10320, false), contains('오전조'));
    expect(formatWon(10320), '10,320원');
    expect(shiftsForMonth(restored, DateTime(2026, 12)), isEmpty);
  });

  testWidgets('shift app displays calendar and add control', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const App());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('근무페이'), findsWidgets);
    expect(find.byKey(const Key('add-shift')), findsOneWidget);
  });
}
