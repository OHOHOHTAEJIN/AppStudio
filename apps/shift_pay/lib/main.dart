import 'dart:io';
import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pay_engine.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const StudioApp(
    title: '근무페이',
    accent: Color(0xFF7CA4FF),
    home: ShiftPayPage(),
  );
}

class ShiftPayPage extends StatefulWidget {
  const ShiftPayPage({super.key});
  @override
  State<ShiftPayPage> createState() => _ShiftPayPageState();
}

class _ShiftPayPageState extends State<ShiftPayPage> {
  List<WorkShift> _shifts = [];
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();
  int _rate = 10320; // 2026 Korean minimum hourly wage; user-editable.
  bool _premiumEnabled = false;
  Map<String, int> _adjustments = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final saved = prefs.getString('work_shifts_v1');
      final raw = prefs.getStringList('work_adjustments_v1') ?? [];
      final adjustments = <String, int>{};
      for (final row in raw) {
        final parts = row.split('=');
        if (parts.length == 2) adjustments[parts.first] = int.tryParse(parts.last) ?? 0;
      }
      setState(() {
        _shifts = saved == null ? [] : WorkShift.decodeAll(saved);
        _rate = prefs.getInt('work_rate_v1') ?? 10320;
        _premiumEnabled = prefs.getBool('work_premium_v1') ?? false;
        _adjustments = adjustments;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loaded = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장된 기록을 읽지 못했습니다. 기존 기록은 변경하지 않았습니다.')),
        );
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('work_shifts_v1', WorkShift.encodeAll(_shifts));
    await prefs.setInt('work_rate_v1', _rate);
    await prefs.setBool('work_premium_v1', _premiumEnabled);
    await prefs.setStringList('work_adjustments_v1',
        _adjustments.entries.map((e) => e.key + '=' + e.value.toString()).toList());
  }

  List<WorkShift> get _current => shiftsForMonth(_shifts, _month);
  MonthlyPay get _summary => MonthlyPay(_current, _rate, _premiumEnabled,
      _adjustments[monthKey(_month)] ?? 0);

  void _moveMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = DateTime(_month.year, _month.month, 1);
    });
  }

  Future<void> _openSettings() async {
    final rateInput = TextEditingController(text: _rate.toString());
    final adjustmentInput = TextEditingController(
        text: (_adjustments[monthKey(_month)] ?? 0).toString());
    var premium = _premiumEnabled;
    final result = await showDialog<(int, bool, int)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('급여 계산 설정'),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              TextField(
                key: const Key('hourly-rate'),
                controller: rateInput,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: '시급 (원)',
                    helperText: '2026년 최저시급 10,320원 기준으로 시작합니다.'),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('가산수당 추정 포함'),
                subtitle: const Text('야간 22~06시와 하루 8시간 초과분에 각각 50% 가산'),
                value: premium,
                onChanged: (value) => update(() => premium = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adjustmentInput,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: InputDecoration(labelText: monthKey(_month) + ' 추가 수당·조정(원)',
                    helperText: '주휴수당 등을 직접 더하거나 음수로 조정'),
              ),
              const SizedBox(height: 8),
              const Text('가산수당 적용은 사업장 규모·근로계약·법정 요건에 따라 다릅니다. '
                  '기본값은 꺼짐이며 실제 지급액을 보장하지 않습니다.',
                  style: TextStyle(fontSize: 12)),
            ],
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
            FilledButton(
              onPressed: () {
                final rate = int.tryParse(rateInput.text);
                final adjustment = int.tryParse(adjustmentInput.text);
                if (rate == null || rate <= 0 || rate > 10000000 ||
                    adjustment == null || adjustment.abs() > 1000000000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('시급과 조정 금액을 확인해 주세요.')));
                  return;
                }
                Navigator.pop(context, (rate, premium, adjustment));
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    rateInput.dispose();
    adjustmentInput.dispose();
    if (result == null || !mounted) return;
    setState(() {
      _rate = result.$1;
      _premiumEnabled = result.$2;
      _adjustments[monthKey(_month)] = result.$3;
    });
    await _save();
  }

  Future<void> _editShift([WorkShift? existing]) async {
    var day = existing?.start ?? _selectedDay;
    var startTime = existing == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay.fromDateTime(existing.start);
    var endTime = existing == null
        ? const TimeOfDay(hour: 18, minute: 0)
        : TimeOfDay.fromDateTime(existing.end);
    final breakInput = TextEditingController(
        text: (existing?.breakMinutes ?? 60).toString());
    final noteInput = TextEditingController(text: existing?.note ?? '');
    final value = await showModalBottomSheet<WorkShift>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, change) => Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20,
            MediaQuery.viewInsetsOf(context).bottom + 20),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? '근무 기록 추가' : '근무 기록 수정',
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  final chosen = await showDatePicker(context: context,
                    initialDate: day, firstDate: DateTime(2020),
                    lastDate: DateTime(2035));
                  if (chosen != null) change(() => day = chosen);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text('근무일 ' + dateKey(day)),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () async {
                    final chosen = await showTimePicker(context: context,
                        initialTime: startTime);
                    if (chosen != null) change(() => startTime = chosen);
                  },
                  child: Text('출근 ' + startTime.format(context)),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(
                  onPressed: () async {
                    final chosen = await showTimePicker(context: context,
                        initialTime: endTime);
                    if (chosen != null) change(() => endTime = chosen);
                  },
                  child: Text('퇴근 ' + endTime.format(context)),
                )),
              ]),
              const SizedBox(height: 10),
              const StudioNotice(message: '퇴근 시간이 출근 시간보다 이르거나 같으면 다음 날 퇴근으로 계산합니다.'),
              const SizedBox(height: 10),
              TextField(
                controller: breakInput,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: '휴게 시간 (분)', hintText: '60'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteInput,
                maxLength: 80,
                decoration: const InputDecoration(labelText: '메모 (선택)',
                    hintText: '오전조, 매장 A 등'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('save-shift'),
                icon: const Icon(Icons.check),
                label: const Text('기록 저장'),
                onPressed: () {
                  final starts = DateTime(day.year, day.month, day.day,
                      startTime.hour, startTime.minute);
                  var ends = DateTime(day.year, day.month, day.day,
                      endTime.hour, endTime.minute);
                  if (!ends.isAfter(starts)) ends = ends.add(const Duration(days: 1));
                  final breakMinutes = int.tryParse(breakInput.text);
                  final gross = ends.difference(starts).inMinutes;
                  if (breakMinutes == null || breakMinutes < 0 ||
                      breakMinutes >= gross) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('휴게 시간은 실제 근무 시간보다 짧아야 합니다.')));
                    return;
                  }
                  Navigator.pop(context, WorkShift(
                    id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                    start: starts, end: ends, breakMinutes: breakMinutes,
                    note: noteInput.text.trim(),
                  ));
                },
              ),
            ],
          )),
        ),
      ),
    );
    breakInput.dispose();
    noteInput.dispose();
    if (value == null || !mounted) return;
    setState(() {
      _shifts.removeWhere((shift) => shift.id == value.id);
      _shifts.add(value);
      _month = DateTime(value.start.year, value.start.month);
      _selectedDay = DateTime(value.start.year, value.start.month, value.start.day);
    });
    await _save();
  }

  Future<void> _deleteShift(WorkShift value) async {
    final confirmed = await showDialog<bool>(context: context,
      builder: (context) => AlertDialog(
        title: const Text('근무 기록 삭제'),
        content: Text(dateKey(value.start) + '의 근무 기록을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _shifts.removeWhere((shift) => shift.id == value.id));
    await _save();
  }

  Future<void> _shareCsv() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(dir.path + '/geunmupay_' + monthKey(_month) + '.csv');
      await file.writeAsString(csvForMonth(_current, _rate, _premiumEnabled));
      await Share.shareXFiles([XFile(file.path)], text: '근무페이 근무 기록');
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV 내보내기 실패: $error')));
    }
  }

  Widget _calendar() {
    final first = DateTime(_month.year, _month.month, 1);
    final startOffset = first.weekday % 7;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final cellCount = ((startOffset + days + 6) ~/ 7) * 7;
    final shiftDays = _current.map((e) => e.start.day).toSet();
    return StudioCard(child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(tooltip: '이전 달',
            onPressed: () => _moveMonth(-1),
            icon: const Icon(Icons.chevron_left)),
        Text(_month.year.toString() + '년 ' + _month.month.toString() + '월',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800)),
        IconButton(tooltip: '다음 달',
            onPressed: () => _moveMonth(1),
            icon: const Icon(Icons.chevron_right)),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        for (final label in ['일', '월', '화', '수', '목', '금', '토'])
          Expanded(child: Text(label, textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFAAB6CC), fontSize: 12))),
      ]),
      const SizedBox(height: 5),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cellCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3,
          mainAxisExtent: 44,
        ),
        itemBuilder: (context, index) {
          final day = index - startOffset + 1;
          if (day < 1 || day > days) return const SizedBox.shrink();
          final selected = _selectedDay.year == _month.year &&
              _selectedDay.month == _month.month && _selectedDay.day == day;
          final hasShift = shiftDays.contains(day);
          return InkWell(
            key: Key('calendar-day-$day'),
            borderRadius: BorderRadius.circular(9),
            onTap: () => setState(() =>
              _selectedDay = DateTime(_month.year, _month.month, day)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(day.toString(), style: TextStyle(fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                if (hasShift) Container(
                  margin: const EdgeInsets.only(top: 3),
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ]),
            ),
          );
        },
      ),
      const SizedBox(height: 10),
      FilledButton.icon(
        key: const Key('add-shift'),
        onPressed: _loaded ? () => _editShift() : null,
        icon: const Icon(Icons.add),
        label: Text(dateKey(_selectedDay) + ' 근무 추가'),
      ),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    return StudioScreen(
      title: '근무페이',
      subtitle: '출퇴근을 기록하고 예상 급여를 한눈에 확인하세요.',
      actions: [
        IconButton(
          tooltip: '시급·수당 설정',
          onPressed: _loaded ? _openSettings : null,
          icon: const Icon(Icons.tune_outlined),
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        StudioHero(
          icon: Icons.payments_outlined,
          title: monthKey(_month) + ' 예상 급여',
          description: '세금·4대보험 공제 전 추정액',
          trailing: const Icon(Icons.wallet, size: 26),
        ),
        const SizedBox(height: 14),
        StudioCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(formatWon(summary.grossEstimateKrw),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              )),
            const SizedBox(height: 7),
            Text('기본급 ' + formatWon(summary.baseKrw) +
              ' · 가산 ' + formatWon(summary.premiumKrw)),
            Text('기타 수당·조정 ' + formatWon(summary.adjustmentKrw),
              style: const TextStyle(color: Color(0xFFAAB6CC))),
          ],
        )),
        const SizedBox(height: 12),
        AdaptiveStatGrid(children: [
          StatBox(label: '근무일', value: _current.map((e) =>
              dateKey(e.start)).toSet().length.toString() + '일',
              icon: Icons.calendar_month),
          StatBox(label: '총 근무', value: formatHours(summary.minutes),
              icon: Icons.schedule),
          StatBox(label: '야간 추정', value: formatHours(summary.nights),
              icon: Icons.nights_stay_outlined),
          StatBox(label: '시급', value: formatWon(_rate),
              icon: Icons.currency_exchange),
        ]),
        const SizedBox(height: 18),
        StudioSectionTitle(
          title: '근무 달력',
          subtitle: '날짜를 눌러 선택하고 근무를 추가하세요.',
          trailing: IconButton(tooltip: '급여 계산 설정',
            onPressed: _openSettings, icon: const Icon(Icons.settings_outlined)),
        ),
        _calendar(),
        const SizedBox(height: 16),
        StudioSectionTitle(
          title: '이번 달 근무 내역',
          subtitle: _current.length.toString() + '건의 근무 기록',
          trailing: IconButton(
            tooltip: 'CSV로 내보내기',
            onPressed: _current.isEmpty ? null : _shareCsv,
            icon: const Icon(Icons.file_download_outlined),
          ),
        ),
        if (_current.isEmpty)
          const StudioNotice(message: '기록이 없습니다. 달력에서 날짜를 선택하고 근무를 추가해 주세요.')
        else
          for (final shift in _current) ...[
            StudioCard(padding: 13, child: Row(children: [
              Container(
                width: 46, height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF283854),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(shift.start.day.toString() + '일',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shift.start.hour.toString().padLeft(2, '0') + ':' +
                      shift.start.minute.toString().padLeft(2, '0') + ' ~ ' +
                      shift.end.hour.toString().padLeft(2, '0') + ':' +
                      shift.end.minute.toString().padLeft(2, '0') +
                      (shift.end.day != shift.start.day ? ' (+1일)' : ''),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(formatHours(shift.paidMinutes) + ' · ' +
                    formatWon(calculateShiftPay(shift,
                        hourlyRate: _rate, applyPremiums: _premiumEnabled).totalKrw),
                    style: const TextStyle(color: Color(0xFFAAB6CC), fontSize: 12)),
                  if (shift.note.isNotEmpty)
                    Text(shift.note, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                ],
              )),
              IconButton(
                tooltip: '수정',
                onPressed: () => _editShift(shift),
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              IconButton(
                tooltip: '삭제',
                onPressed: () => _deleteShift(shift),
                icon: const Icon(Icons.delete_outline, size: 19),
              ),
            ])),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 16),
        const StudioNotice(
          message: '이 계산기는 급여 추정용입니다. 야간 22~06시·하루 8시간 초과 가산은 설정에서 직접 켤 수 있습니다. '
          '휴게시간은 야간 시간에 비례 배분하며, 주 40시간 초과·휴일·주휴수당·세금·보험료는 자동 계산하지 않습니다. '
          '자정을 넘는 근무는 출근일의 달에 포함합니다. 실제 급여명세서와 차이가 날 수 있습니다.',
        ),
        const SizedBox(height: 8),
        const StudioNotice(message: '근무 기록은 기기에만 저장됩니다. 새 휴대폰으로 이동하기 전 CSV를 내보내세요.'),
      ]),
    );
  }
}
