import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_theme.dart';
import '../../services/planner_service.dart';

class PlannerCalendarPage extends StatefulWidget {
  final String? initialView;
  final String? initialFilter;
  final String? initialDate;
  final bool embedded;

  const PlannerCalendarPage({
    super.key,
    this.initialView,
    this.initialFilter,
    this.initialDate,
    this.embedded = false,
  });

  @override
  State<PlannerCalendarPage> createState() => _PlannerCalendarPageState();
}

class _PlannerCalendarPageState extends State<PlannerCalendarPage> {
  DateTime _selected = DateTime.now();
  DateTime _displayMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _viewMode = 'month';
  String _todoFilter = 'all';
  String? _curriculumId;

  @override
  void initState() {
    super.initState();
    if (widget.initialView == 'week' || widget.initialView == 'month') _viewMode = widget.initialView!;
    if (['all', 'todo', 'in_progress', 'done'].contains(widget.initialFilter)) _todoFilter = widget.initialFilter!;
    final d = DateTime.tryParse(widget.initialDate ?? '');
    if (d != null) {
      _selected = DateTime(d.year, d.month, d.day);
      _displayMonth = DateTime(d.year, d.month, 1);
    }
  }

  String _sharePath() {
    final ymd = _selected.toIso8601String().substring(0, 10);
    return '/calendar?view=$_viewMode&filter=$_todoFilter&date=$ymd';
  }

  Future<void> _copyShareLink() async {
    final absolute = kIsWeb ? '${Uri.base.origin}${_sharePath()}' : _sharePath();
    await Clipboard.setData(ClipboardData(text: absolute));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공유 링크 복사 완료')));
  }

  Future<void> _shareCurrentState() async {
    final absolute = kIsWeb ? '${Uri.base.origin}${_sharePath()}' : _sharePath();
    await Share.share('스터디 파일럿 학습 캘린더 공유\n$absolute');
  }

  Future<void> _showShareQr() async {
    final absolute = kIsWeb ? '${Uri.base.origin}${_sharePath()}' : _sharePath();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('캘린더 공유 QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: absolute, size: 220),
            const SizedBox(height: 8),
            SelectableText(absolute, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime day, String? ymd) {
    if (ymd == null) return false;
    final d = DateTime.tryParse(ymd);
    if (d == null) return false;
    return day.year == d.year && day.month == d.month && day.day == d.day;
  }

  List<DateTime> _monthDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final start = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    return List.generate(35, (i) => DateTime(start.year, start.month, start.day + i));
  }

  List<DateTime> _weekDays(DateTime day) {
    final start = day.subtract(Duration(days: day.weekday % 7));
    return List.generate(7, (i) => DateTime(start.year, start.month, start.day + i));
  }

  bool _todoPass(Map<String, dynamic> t) {
    final s = (t['status'] ?? 'todo').toString();
    if (_todoFilter == 'all') return true;
    return s == _todoFilter;
  }

  void _changeMonth(int delta) {
    setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta, 1));
  }

  String _segmentLabel(String name) {
    final trimmed = name.trim();
    return trimmed.runes.length <= 7 ? trimmed : '${String.fromCharCodes(trimmed.runes.take(7))}...';
  }

  Future<void> _showDayDetailSheet({required DateTime day, required Map<String, dynamic>? curriculum, required List<Map<String, dynamic>> todos}) async {
    final dayTodos = todos.where((t) => _isSameDay(day, t['due_date'] as String?)).toList();
    final segment = curriculum == null ? null : PlannerService.findSegmentForDate(curriculum, day);
    final allSegments = curriculum == null ? const <Map<String, dynamic>>[] : PlannerService.buildCurriculumSegments(curriculum);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailSheet(day: day, segment: segment, allSegments: allSegments, todos: dayTodos),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: Future.wait([PlannerService.listCurriculums(), PlannerService.listTodos()]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final curriculums = snapshot.data![0];
          final todos = snapshot.data![1];
          if (_curriculumId == null && curriculums.isNotEmpty) {
            final sample = curriculums.cast<Map<String, dynamic>>().where((c) => c['id'] == 'demo-curriculum-study-pilot');
            _curriculumId = (sample.isNotEmpty ? sample.first['id'] : curriculums.first['id']) as String;
          }

          final selectedCurriculumTodos = todos.where((t) {
            if (_curriculumId == null) return true;
            return t['curriculum_id'] == _curriculumId;
          }).where(_todoPass).toList();

          final selectedCurriculum = _curriculumId == null ? null : curriculums.cast<Map<String, dynamic>?>().firstWhere((c) => c?['id'] == _curriculumId, orElse: () => curriculums.isNotEmpty ? curriculums.first : null);
          final visibleDays = _viewMode == 'week' ? _weekDays(_selected) : _monthDays(_displayMonth);
          final selectedDayTodos = selectedCurriculumTodos.where((t) => _isSameDay(_selected, t['due_date'] as String?)).toList();
          final completedCount = selectedDayTodos.where((t) => (t['status'] ?? 'todo') == 'done').length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: const Color(0x190050CB), borderRadius: BorderRadius.circular(999)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.primaryStrong, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('학습 캘린더', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
                  const Spacer(),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_rounded, color: AppColors.lightMuted)),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ViewButton(label: '월간', active: _viewMode == 'month', onTap: () => setState(() => _viewMode = 'month')),
                      _ViewButton(label: '주간', active: _viewMode == 'week', onTap: () => setState(() => _viewMode = 'week')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryStrong)),
                  Expanded(
                    child: Text('${_displayMonth.year}년 ${_displayMonth.month}월', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.lightText)),
                  ),
                  IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryStrong)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(label: '전체', active: _todoFilter == 'all', onTap: () => setState(() => _todoFilter = 'all')),
                    _FilterChip(label: '대기', active: _todoFilter == 'todo', onTap: () => setState(() => _todoFilter = 'todo')),
                    _FilterChip(label: '진행중', active: _todoFilter == 'in_progress', onTap: () => setState(() => _todoFilter = 'in_progress')),
                    _FilterChip(label: '완료', active: _todoFilter == 'done', onTap: () => setState(() => _todoFilter = 'done')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: AppTheme.glassCard(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(child: Center(child: Text('SUN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0x99BA1A1A))))),
                        Expanded(child: Center(child: Text('MON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)))),
                        Expanded(child: Center(child: Text('TUE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)))),
                        Expanded(child: Center(child: Text('WED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)))),
                        Expanded(child: Center(child: Text('THU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)))),
                        Expanded(child: Center(child: Text('FRI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)))),
                        Expanded(child: Center(child: Text('SAT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0x990066FF))))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GridView.builder(
                      itemCount: visibleDays.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 12),
                      itemBuilder: (context, index) {
                        final day = visibleDays[index];
                        final selected = day.year == _selected.year && day.month == _selected.month && day.day == _selected.day;
                        final inMonth = day.month == _displayMonth.month;
                        final hasTodo = selectedCurriculumTodos.any((t) => _isSameDay(day, t['due_date'] as String?));
                        final segment = selectedCurriculum == null ? null : PlannerService.findSegmentForDate(selectedCurriculum, day);
                        final dayTodoCount = selectedCurriculumTodos.where((t) => _isSameDay(day, t['due_date'] as String?)).length;
                        return InkWell(
                          onTap: () {
                            setState(() => _selected = day);
                            _showDayDetailSheet(day: day, curriculum: selectedCurriculum, todos: selectedCurriculumTodos);
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF0050CB) : Colors.transparent,
                                  shape: BoxShape.circle,
                                  boxShadow: selected ? const [BoxShadow(color: Color(0x330050CB), blurRadius: 18)] : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? Colors.white : (inMonth ? AppColors.lightText : AppColors.lightMuted.withValues(alpha: 0.3)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (segment != null)
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Color(int.parse((segment['color'] ?? PlannerService.segmentPalette.first).toString())).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _segmentLabel((segment['name'] ?? '-').toString()),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 7, height: 1.1, fontWeight: FontWeight.w700, color: Color(int.parse((segment['color'] ?? PlannerService.segmentPalette.first).toString()))),
                                      ),
                                    ),
                                    if (dayTodoCount > 0) ...[
                                      const SizedBox(height: 3),
                                      Container(
                                        width: 18,
                                        height: 18,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(color: selected ? Colors.white : const Color(0xFF006689), shape: BoxShape.circle),
                                        child: Text('$dayTodoCount', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: selected ? const Color(0xFF006689) : Colors.white)),
                                      ),
                                    ],
                                  ],
                                )
                              else if (hasTodo)
                                Container(
                                  width: 18,
                                  height: 18,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: selected ? Colors.white : const Color(0xFF006689), shape: BoxShape.circle),
                                  child: Text('$dayTodoCount', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: selected ? const Color(0xFF006689) : Colors.white)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -6))],
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                child: Column(
                  children: [
                    Container(width: 48, height: 4, decoration: BoxDecoration(color: AppColors.lightMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(999))),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text('${_selected.month}월 ${_selected.day}일의 미션', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0x190050CB), borderRadius: BorderRadius.circular(999)),
                          child: Text('완료 $completedCount / ${selectedDayTodos.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (selectedDayTodos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('선택한 날짜에 등록된 미션이 아직 없어.', style: TextStyle(color: AppColors.lightMuted)),
                      )
                    else
                      ...selectedDayTodos.map((todo) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MissionTile(todo: todo),
                          )),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _shareCurrentState,
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('공유'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _SquareActionButton(icon: Icons.qr_code_2_rounded, onTap: _showShareQr),
                        const SizedBox(width: 10),
                        _SquareActionButton(icon: Icons.link_rounded, onTap: _copyShareLink),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ViewButton({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(color: active ? const Color(0xFF0050CB) : Colors.transparent, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.lightMuted)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0050CB) : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.lightMuted)),
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final Map<String, dynamic> todo;
  const _MissionTile({required this.todo});
  @override
  Widget build(BuildContext context) {
    final status = (todo['status'] ?? 'todo').toString();
    final isDone = status == 'done';
    final isProgress = status == 'in_progress';
    final accent = isDone ? Colors.green : (isProgress ? AppColors.primaryStrong : AppColors.lightMuted);
    return Container(
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: accent, width: 2)),
            alignment: Alignment.center,
            child: Icon(isDone ? Icons.check_rounded : (isProgress ? Icons.rocket_launch_rounded : Icons.description_outlined), color: accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(todo['title'] ?? '-', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                const SizedBox(height: 4),
                Text('상태: $status · 마감: ${todo['due_date'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded, color: AppColors.lightMuted),
        ],
      ),
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareActionButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 52,
        height: 52,
        decoration: AppTheme.glassCard(),
        child: Icon(icon, color: AppColors.primaryStrong),
      ),
    );
  }
}

class _DayDetailSheet extends StatelessWidget {
  final DateTime day;
  final Map<String, dynamic>? segment;
  final List<Map<String, dynamic>> allSegments;
  final List<Map<String, dynamic>> todos;

  const _DayDetailSheet({required this.day, required this.segment, required this.allSegments, required this.todos});

  @override
  Widget build(BuildContext context) {
    final segmentColor = segment == null ? AppColors.primaryStrong : Color(int.parse((segment!['color'] ?? PlannerService.segmentPalette.first).toString()));
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.lightMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(999)))),
            const SizedBox(height: 18),
            Text('${day.month}월 ${day.day}일 상세', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.lightText)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: segmentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: segmentColor.withValues(alpha: 0.28))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('오늘 진행 구간', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
                const SizedBox(height: 6),
                Text(segment?['name'] ?? '해당 구간 없음', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: segmentColor)),
                if (segment != null) ...[
                  const SizedBox(height: 6),
                  Text('${segment!['start_date']} ~ ${segment!['end_date']}', style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            const Text('커리큘럼 진행 구간', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.lightText)),
            const SizedBox(height: 10),
            ...allSegments.map((item) {
              final color = Color(int.parse((item['color'] ?? PlannerService.segmentPalette.first).toString()));
              final active = segment != null && item['id'] == segment!['id'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: active ? 0.18 : 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: active ? 0.35 : 0.18))),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item['name'] ?? '-', style: TextStyle(fontWeight: FontWeight.w800, color: active ? color : AppColors.lightText))),
                  Text('${item['start_date']} ~ ${item['end_date']}', style: const TextStyle(fontSize: 11, color: AppColors.lightMuted)),
                ]),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('오늘 해야 할 일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0x190050CB), borderRadius: BorderRadius.circular(999)),
                  child: Text('${todos.length}개', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (todos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('이 날짜에 등록된 할일이 아직 없어.', style: TextStyle(color: AppColors.lightMuted)),
              )
            else
              ...todos.map((todo) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
                    child: Row(children: [
                      Icon(
                        (todo['status'] ?? 'todo') == 'done'
                            ? Icons.check_circle_rounded
                            : (todo['status'] ?? 'todo') == 'in_progress'
                                ? Icons.adjust_rounded
                                : Icons.radio_button_unchecked_rounded,
                        color: (todo['status'] ?? 'todo') == 'done' ? Colors.green : AppColors.primaryStrong,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(todo['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text((todo['priority'] ?? 'medium').toString(), style: const TextStyle(fontSize: 11, color: AppColors.lightMuted)),
                    ]),
                  )),
          ],
        ),
      ),
    );
  }
}
