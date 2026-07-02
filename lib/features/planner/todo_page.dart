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
  String _quickPriority = 'high';
  final TextEditingController _quickTodoCtrl = TextEditingController();
  bool _addingTodo = false;

  @override
  void dispose() {
    _quickTodoCtrl.dispose();
    super.dispose();
  }

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
            Text('• 오늘 집중해야 할 일과 밀린 일, 진행 중인 일을 먼저 보게 구성했어.'),
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

  Future<void> _addQuickTodo() async {
    if (_curriculumId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('먼저 커리큘럼을 선택해줘.')));
      return;
    }
    if (_quickTodoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('추가할 할일 내용을 입력해줘.')));
      return;
    }
    setState(() => _addingTodo = true);
    try {
      await PlannerService.createTodo(
        curriculumId: _curriculumId!,
        title: _quickTodoCtrl.text.trim(),
        dueDate: _selectedDate,
        priority: _quickPriority,
      );
      _quickTodoCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('선택 날짜에 할일을 추가했어.')));
      setState(() {});
    } finally {
      if (mounted) setState(() => _addingTodo = false);
    }
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

          final selectedCurriculum = curriculums.where((c) => c['id'] == _curriculumId).cast<Map<String, dynamic>?>().firstWhere(
                (c) => c != null,
                orElse: () => curriculums.isNotEmpty ? curriculums.first : null,
              );
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

          final today = DateTime.now();
          final todayTodos = selectedCurriculumTodos.where((t) => _sameDay(today, t['due_date'] as String?)).toList();
          final overdueTodos = selectedCurriculumTodos.where((t) {
            final due = DateTime.tryParse((t['due_date'] ?? '').toString());
            if (due == null) return false;
            return DateTime(due.year, due.month, due.day).isBefore(DateTime(today.year, today.month, today.day)) && (t['status'] ?? 'todo') != 'done';
          }).toList();
          final inProgressTodos = selectedCurriculumTodos.where((t) => (t['status'] ?? 'todo') == 'in_progress').toList();
          final focusTodo = inProgressTodos.isNotEmpty ? inProgressTodos.first : (todayTodos.isNotEmpty ? todayTodos.first : (overdueTodos.isNotEmpty ? overdueTodos.first : null));

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
                    child: const Icon(Icons.task_alt_rounded, color: AppColors.primaryStrong),
                  ),
                  const SizedBox(width: 10),
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
                ],
              ),
              const SizedBox(height: 14),
              _FocusHeaderCard(
                title: selectedCurriculum?['title'] ?? '현재 커리큘럼 없음',
                progress: progress,
                todayCount: todayTodos.length,
                inProgressCount: inProgressTodos.length,
                overdueCount: overdueTodos.length,
                focusTodo: focusTodo?['title']?.toString(),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: AppTheme.glassCard(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('빠른 추가', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _quickTodoCtrl,
                      decoration: InputDecoration(
                        hintText: '${_selectedDate.month}월 ${_selectedDate.day}일에 끝낼 일을 적어줘',
                        suffixIcon: IconButton(onPressed: _addingTodo ? null : _addQuickTodo, icon: const Icon(Icons.add_circle_rounded)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PriorityChip(label: '중요', active: _quickPriority == 'high', onTap: () => setState(() => _quickPriority = 'high')),
                        _PriorityChip(label: '보통', active: _quickPriority == 'medium', onTap: () => setState(() => _quickPriority = 'medium')),
                        _PriorityChip(label: '가볍게', active: _quickPriority == 'low', onTap: () => setState(() => _quickPriority = 'low')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 10, crossAxisSpacing: 2, mainAxisExtent: 58),
                      itemBuilder: (context, index) {
                        final day = visibleDays[index];
                        final selected = day.year == _selectedDate.year && day.month == _selectedDate.month && day.day == _selectedDate.day;
                        final inMonth = day.month == _displayMonth.month;
                        final dayTodos = selectedCurriculumTodos.where((t) => _sameDay(day, t['due_date'] as String?)).length;
                        return InkWell(
                          onTap: () => setState(() => _selectedDate = day),
                          borderRadius: BorderRadius.circular(999),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Container(
                                width: 40,
                                height: 40,
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
              const SizedBox(height: 18),
              _ExecutionSummarySection(
                selectedDate: _selectedDate,
                pending: pending,
                inFlight: inFlight,
                completed: completed,
                overdueCount: overdueTodos.length,
              ),
              const SizedBox(height: 14),
              ...[
                if (focusTodo != null)
                  _TodoLaneSection(
                    title: '지금 가장 중요한 일',
                    subtitle: '먼저 이것부터 끝내보자.',
                    todos: [focusTodo],
                    variant: 'focus',
                    onTap: _cycleStatus,
                  ),
                if (pending.isNotEmpty)
                  _TodoLaneSection(
                    title: '오늘 해야 할 일',
                    subtitle: '선택 날짜에 남아 있는 핵심 미션이야.',
                    todos: pending,
                    variant: 'pending',
                    onTap: _cycleStatus,
                  ),
                if (inFlight.isNotEmpty)
                  _TodoLaneSection(
                    title: '진행 중',
                    subtitle: '지금 손대고 있는 작업 흐름이야.',
                    todos: inFlight,
                    variant: 'progress',
                    onTap: _cycleStatus,
                  ),
                if (completed.isNotEmpty)
                  _TodoLaneSection(
                    title: '완료한 일',
                    subtitle: '완료한 일은 체크 감각이 살아있게 남겨둘게.',
                    todos: completed,
                    variant: 'done',
                    onTap: _cycleStatus,
                  ),
                if (pending.isEmpty && inFlight.isEmpty && completed.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.glassCard(),
                    child: const Text('선택한 날짜에 등록된 할일이 아직 없어. 위에서 바로 추가해봐.', style: TextStyle(color: AppColors.lightMuted)),
                  ),
              ].expand((widget) => [widget, const SizedBox(height: 14)]),
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

class _FocusHeaderCard extends StatelessWidget {
  final String title;
  final double progress;
  final int todayCount;
  final int inProgressCount;
  final int overdueCount;
  final String? focusTodo;

  const _FocusHeaderCard({required this.title, required this.progress, required this.todayCount, required this.inProgressCount, required this.overdueCount, required this.focusTodo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TODAY FOCUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.lightText)),
          const SizedBox(height: 8),
          Text(focusTodo == null ? '오늘 바로 실행할 할일을 골라보자.' : '지금 가장 먼저 끝낼 일 · $focusTodo', style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.lightMuted)),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: progress == 0 ? 0.08 : progress, minHeight: 8, borderRadius: BorderRadius.circular(999)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniStatCard(label: '오늘', value: '$todayCount개')),
              const SizedBox(width: 8),
              Expanded(child: _MiniStatCard(label: '진행중', value: '$inProgressCount개')),
              const SizedBox(width: 8),
              Expanded(child: _MiniStatCard(label: '밀림', value: '$overdueCount개')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.34), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.lightText)),
      ]),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PriorityChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: active ? AppColors.primaryStrong : Colors.white.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.lightMuted)),
      ),
    );
  }
}

class _ExecutionSummarySection extends StatelessWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> pending;
  final List<Map<String, dynamic>> inFlight;
  final List<Map<String, dynamic>> completed;
  final int overdueCount;

  const _ExecutionSummarySection({required this.selectedDate, required this.pending, required this.inFlight, required this.completed, required this.overdueCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${selectedDate.month}월 ${selectedDate.day}일 실행 요약', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightText)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(label: '대기', value: '${pending.length}개'),
              _SummaryPill(label: '진행중', value: '${inFlight.length}개'),
              _SummaryPill(label: '완료', value: '${completed.length}개'),
              _SummaryPill(label: '밀린 일정', value: '$overdueCount개'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.34), borderRadius: BorderRadius.circular(999)),
      child: Text('$label $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightText)),
    );
  }
}

class _TodoLaneSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> todos;
  final String variant;
  final Future<void> Function(Map<String, dynamic>) onTap;

  const _TodoLaneSection({required this.title, required this.subtitle, required this.todos, required this.variant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightText)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...todos.map((todo) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TodoMissionCard(todo: todo, variant: variant, onTap: () => onTap(todo)),
            )),
      ],
    );
  }
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
    final isInFlight = variant == 'progress';
    final isDone = variant == 'done';
    final isFocus = variant == 'focus';
    final accent = isFocus ? const Color(0xFFFFB020) : isInFlight ? AppColors.primaryStrong : (isDone ? const Color(0xFF77D1FF) : const Color(0xFFC2C6D8));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: AppTheme.glassCard().copyWith(
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(
                isDone ? Icons.check_circle_rounded : isInFlight ? Icons.rocket_launch_rounded : isFocus ? Icons.local_fire_department_rounded : Icons.radio_button_unchecked_rounded,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(todo['title'] ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDone ? AppColors.lightMuted : AppColors.lightText, decoration: isDone ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 4),
                  Text('우선순위 ${(todo['priority'] ?? 'medium').toString()} · 상태 ${(todo['status'] ?? 'todo').toString()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.lightMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.lightMuted),
          ],
        ),
      ),
    );
  }
}
