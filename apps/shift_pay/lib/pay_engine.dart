// ignore_for_file: prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures
import 'dart:convert';
import 'dart:math' as math;

class WorkShift {
  const WorkShift({
    required this.id,
    required this.start,
    required this.end,
    required this.breakMinutes,
    this.note = '',
  });
  final String id;
  final DateTime start;
  final DateTime end;
  final int breakMinutes;
  final String note;

  int get spanMinutes => math.max(0, end.difference(start).inMinutes);
  int get paidMinutes => math.max(0, spanMinutes - breakMinutes);

  /// Night work is 22:00-06:00; break duration is proportionally allocated.
  /// Actual paid night minutes can differ when the true break timing is known.
  int get estimatedNightMinutes {
    final gross = spanMinutes;
    if (gross <= 0) return 0;
    var night = 0;
    for (var i = 0; i < gross; i++) {
      final at = start.add(Duration(minutes: i));
      if (at.hour >= 22 || at.hour < 6) night++;
    }
    return (night * paidMinutes / gross).round().clamp(0, paidMinutes);
  }

  int get dailyOvertimeMinutes => math.max(0, paidMinutes - 8 * 60);

  Map<String, Object> toJson() => {
    'id': id,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'breakMinutes': breakMinutes,
    'note': note,
  };

  factory WorkShift.fromJson(Map<String, dynamic> map) => WorkShift(
    id: map['id'] as String,
    start: DateTime.parse(map['start'] as String),
    end: DateTime.parse(map['end'] as String),
    breakMinutes: (map['breakMinutes'] as num).toInt(),
    note: map['note'] as String? ?? '',
  );

  static List<WorkShift> decodeAll(String raw) {
    final parsed = jsonDecode(raw) as List<dynamic>;
    return parsed.map((value) =>
      WorkShift.fromJson(Map<String, dynamic>.from(value as Map))).toList();
  }

  static String encodeAll(List<WorkShift> shifts) =>
      jsonEncode(shifts.map((e) => e.toJson()).toList());
}

class PayBreakdown {
  const PayBreakdown({
    required this.paidMinutes,
    required this.nightMinutes,
    required this.overtimeMinutes,
    required this.baseKrw,
    required this.nightExtraKrw,
    required this.overtimeExtraKrw,
  });

  final int paidMinutes, nightMinutes, overtimeMinutes;
  final int baseKrw, nightExtraKrw, overtimeExtraKrw;

  int get totalKrw => baseKrw + nightExtraKrw + overtimeExtraKrw;
}

PayBreakdown calculateShiftPay(WorkShift shift, {
  required int hourlyRate,
  bool applyPremiums = false,
}) {
  final net = shift.paidMinutes;
  final night = shift.estimatedNightMinutes;
  final overtime = shift.dailyOvertimeMinutes;
  return PayBreakdown(
    paidMinutes: net,
    nightMinutes: night,
    overtimeMinutes: overtime,
    baseKrw: (net * hourlyRate / 60).round(),
    nightExtraKrw: applyPremiums ? (night * hourlyRate * .5 / 60).round() : 0,
    overtimeExtraKrw: applyPremiums
        ? (overtime * hourlyRate * .5 / 60).round() : 0,
  );
}

class MonthlyPay {
  const MonthlyPay(this.shifts, this.hourlyRate, this.applyPremiums, this.adjustmentKrw);
  final List<WorkShift> shifts;
  final int hourlyRate;
  final bool applyPremiums;
  final int adjustmentKrw;

  int get minutes => shifts.fold(0, (sum, shift) => sum + shift.paidMinutes);
  int get nights => shifts.fold(0, (sum, shift) => sum + shift.estimatedNightMinutes);
  int get overtime => shifts.fold(0, (sum, shift) => sum + shift.dailyOvertimeMinutes);
  int get baseKrw => shifts.fold(0, (sum, shift) =>
      sum + calculateShiftPay(shift, hourlyRate: hourlyRate).baseKrw);
  int get premiumKrw => shifts.fold(0, (sum, shift) {
    final pay = calculateShiftPay(shift, hourlyRate: hourlyRate,
        applyPremiums: applyPremiums);
    return sum + pay.overtimeExtraKrw + pay.nightExtraKrw;
  });
  int get grossEstimateKrw => baseKrw + premiumKrw + adjustmentKrw;
}

String formatWon(num value) {
  final raw = value.round().toString();
  return raw.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',') + '원';
}

String formatHours(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return hours.toString() + '시간';
  return hours.toString() + '시간 ' + rest.toString() + '분';
}

String monthKey(DateTime date) =>
    date.year.toString() + '-' + date.month.toString().padLeft(2, '0');

String dateKey(DateTime date) => monthKey(date) + '-' +
    date.day.toString().padLeft(2, '0');

List<WorkShift> shiftsForMonth(List<WorkShift> shifts, DateTime month) =>
    shifts.where((shift) =>
        shift.start.year == month.year && shift.start.month == month.month)
        .toList()..sort((a, b) => a.start.compareTo(b.start));

String csvForMonth(List<WorkShift> shifts, int rate, bool premiums) {
  final buffer = StringBuffer(
      '\uFEFF날짜,시작,종료,휴게(분),실근무(분),야간추정(분),기본급(원),가산추정(원),합계(원),메모\r\n');
  String quote(String v) => '"' + v.replaceAll('"', '""') + '"';
  for (final shift in shifts) {
    final value = calculateShiftPay(shift, hourlyRate: rate,
        applyPremiums: premiums);
    final start = shift.start;
    final end = shift.end;
    final s = dateKey(start) + ' ' +
        start.hour.toString().padLeft(2, '0') + ':' +
        start.minute.toString().padLeft(2, '0');
    final e = dateKey(end) + ' ' +
        end.hour.toString().padLeft(2, '0') + ':' +
        end.minute.toString().padLeft(2, '0');
    buffer.writeln([
      quote(dateKey(start)), quote(s), quote(e),
      shift.breakMinutes, value.paidMinutes, value.nightMinutes,
      value.baseKrw, value.nightExtraKrw + value.overtimeExtraKrw,
      value.totalKrw, quote(shift.note),
    ].join(',') + '\r');
  }
  return buffer.toString();
}
