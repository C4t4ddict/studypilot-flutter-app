import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../services/planner_service.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  String? _curriculumId;
  DateTime _selectedDate = DateTime.now();
  DateTime _displayMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _viewMode = 'month';

  bool _sameDay(DateTime a, String? ymd) {
    final b = DateTime.tryParse(ymd ?? '');
    if (b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  void _changeMonth(int delta) {
    setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta, 1));
  }

  Future<void> _cycleStatus(Map<String, dynamic> t) async {
    final now = (t['status'] ?? 'todo').toString();
    final next = now == 'todo' ? 'in_progress' : (now == 'in_progress' ? 'done' : 'todo');
    await PlannerService.setTodoStatus(todoId: t['id'] as String, status: next);
    if (mounted) setState(() {});
  }

  Future<void> _showHelpModal() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('할일 탭 안내'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• 이 탭은 날짜별 실행 미션을 확인하고 상태를 바꾸는 공간이야.'),
            SizedBox(height: 8),
            Text('• 커리큘럼을 고르면 해당 학습 항로의 할일만 골라서 볼 수 있어.'),
            SizedBox(height: 8),
            Text('• 날짜를 누르면 그날 해야 할 할일 카드가 아래에 보여.'),
            SizedBox(height: 8),
            Text('• 카드를 누르면 대기 → 진행중 → 완료 순서로 상태가 바뀌어.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('닫기')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: Future.wait([PlannerService.listCurriculums(), PlannerService.listTodos()]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final curriculums = snapshot.data![0];
          final todos = snapshot.data![1];
          if (_curriculumId == null && curriculums.isNotEmpty) {
            _curriculumId = curriculums.first['id'] as String;
          }

          final selectedCurriculumTodos = todos.where((t) {
            if (_curriculumId == null) return true;
            return t['curriculum_id'] == _curriculumId;
          }).toList();
          final visibleDays = _viewMode == 'week' ? _weekDays(_selectedDate) : _monthDays(_displayMonth);
          final selectedTodos = selectedCurriculumTodos.where((t) => _sameDay(_selectedDate, t['due_date'] as String?)).toList();
          final inFlight = selectedTodos.where((t) => (t['status'] ?? 'todo') == 'in_progress').toList();
          final completed = selectedTodos.where((t) => (t['status'] ?? 'todo') == 'done').toList();
          final pending = selectedTodos.where((t) => (t['status'] ?? 'todo') == 'todo').toList();
          final progress = selectedCurriculumTodos.isEmpty ? 0.0 : selectedCurriculumTodos.where((t) => (t['status'] ?? 'todo') == 'done').length / selectedCurriculumTodos.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white), color: Colors.white.withValues(alpha: 0.7)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.person_rounded, color: AppColors.primaryStrong),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        const Text('Mission Log', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _showHelpModal,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const Text('?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_rounded, color: AppColors.primaryStrong)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: AppTheme.glassCard(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CURRENT MISSION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, backgroundColor: AppColors.primaryStrong)),
                    const SizedBox(height: 10),
                    Text(curriculums.isEmpty ? 'No Curriculum' : (curriculums.firstWhere((c) => c['id'] == _curriculumId, orElse: () => curriculums.first)['title'] ?? '-'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('68% CLEARED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
                        const Spacer(),
                        SizedBox(
                          width: 160,
                          child: LinearProgressIndicator(value: progress == 0 ? 0.18 : progress, minHeight: 6, borderRadius: BorderRadius.circular(999)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _ToggleButton(label: 'Weekly', active: _viewMode == 'week', onTap: () => setState(() => _viewMode = 'week')),
                          _ToggleButton(label: 'Monthly', active: _viewMode == 'month', onTap: () => setState(() => _viewMode = 'month')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: curriculums.map<Widget>((c) {
                          final active = c['id'] == _curriculumId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _curriculumId = c['id'] as String),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(color: active ? AppColors.primaryStrong : Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(999)),
                                child: Text(c['title'] ?? '-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.lightText)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryStrong)),
                  Expanded(
                    child: Text('${_displayMonth.year} ${_monthName(_displayMonth.month)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
                  ),
                  IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryStrong)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: AppTheme.glassCard(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(child: Center(child: Text('MON', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)))),
                        Expanded(child: Center(child: Text('TUE', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)))),
                        Expanded(child: Center(child: Text('WED', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)))),
                        Expanded(child: Center(child: Text('THU', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)))),
                        Expanded(child: Center(child: Text('FRI', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)))),
                        Expanded(child: Center(child: Text('SAT', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)))),
                        Expanded(child: Center(child: Text('SUN', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      itemCount: visibleDays.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8),
                      itemBuilder: (context, index) {
                        final day = visibleDays[index];
                        final selected = day.year == _selectedDate.year && day.month == _selectedDate.month && day.day == _selectedDate.day;
                        final inMonth = day.month == _displayMonth.month;
                        final dayTodos = selectedCurriculumTodos.where((t) => _sameDay(day, t['due_date'] as String?)).length;
                        return InkWell(
                          onTap: () => setState(() => _selectedDate = day),
                          borderRadius: BorderRadius.circular(999),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primaryStrong : (dayTodos >= 3 ? const Color(0xFFDAE1FF) : Colors.transparent),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text('${day.day}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? Colors.white : (inMonth ? AppColors.lightText : AppColors.lightMuted.withValues(alpha: 0.4)))),
                              ),
                              if (dayTodos > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(dayTodos > 3 ? 3 : dayTodos, (_) => Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: const BoxDecoration(color: AppColors.primaryStrong, shape: BoxShape.circle))),
                                ),
                              ]
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Tasks for ${_monthName(_selectedDate.month)} ${_selectedDate.day}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.lightText)),
              const SizedBox(height: 14),
              Wrap(
                runSpacing: 14,
                spacing: 14,
                children: [
                  ...inFlight.map((t) => _TodoMissionCard(todo: t, variant: 'in_flight', onTap: () => _cycleStatus(t))),
                  ...completed.map((t) => _TodoMissionCard(todo: t, variant: 'done', onTap: () => _cycleStatus(t))),
                  ...pending.map((t) => _TodoMissionCard(todo: t, variant: 'pending', onTap: () => _cycleStatus(t))),
                  if (selectedTodos.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.glassCard(),
                      child: const Text('선택한 날짜에 등록된 할일이 아직 없어.', style: TextStyle(color: AppColors.lightMuted)),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

String _monthName(int month) {
  const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  return names[month - 1];
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: active ? Colors.white.withValues(alpha: 0.6) : Colors.transparent, borderRadius: BorderRadius.circular(999)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: active ? AppColors.primaryStrong : AppColors.lightMuted)),
        ),
      ),
    );
  }
}

class _TodoMissionCard extends StatelessWidget {
  final Map<String, dynamic> todo;
  final String variant;
  final VoidCallback onTap;
  const _TodoMissionCard({required this.todo, required this.variant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isInFlight = variant == 'in_flight';
    final isDone = variant == 'done';
    final accent = isInFlight ? AppColors.primaryStrong : (isDone ? const Color(0xFF77D1FF) : const Color(0xFFC2C6D8));
    return SizedBox(
      width: MediaQuery.of(context).size.width > 700 ? (MediaQuery.of(context).size.width - 68) / 2 : double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: AppTheme.glassCard().copyWith(
            border: Border.all(color: isInFlight ? AppColors.primaryStrong : Colors.white.withValues(alpha: 0.6)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isDone ? Icons.check_circle_rounded : isInFlight ? Icons.adjust_rounded : Icons.radio_button_unchecked_rounded, color: accent),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                    child: Text(isDone ? 'MISSION ACCOMPLISHED' : isInFlight ? 'IN FLIGHT' : 'PENDING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent)),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(todo['title'] ?? '-', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDone ? AppColors.lightMuted : AppColors.lightText, decoration: isDone ? TextDecoration.lineThrough : null)),
              const SizedBox(height: 10),
              Text('상태: ${(todo['status'] ?? 'todo').toString()} · 우선순위: ${(todo['priority'] ?? 'medium').toString()}', style: const TextStyle(fontSize: 14, color: AppColors.lightMuted)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Text(isDone ? '완료 처리됨' : isInFlight ? '진행 중 미션' : '대기 중 미션', style: const TextStyle(fontSize: 12, color: AppColors.lightMuted))),
                  Icon(isDone ? Icons.restart_alt_rounded : isInFlight ? Icons.more_vert_rounded : Icons.arrow_forward_rounded, color: AppColors.lightMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
