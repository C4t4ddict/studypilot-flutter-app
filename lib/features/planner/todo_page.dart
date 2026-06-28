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
  final _title = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime _displayMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _viewMode = 'month';
  String _priority = 'medium';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_curriculumId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 커리큘럼을 선택해줘.')),
      );
      return;
    }
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('투두 제목을 입력해줘.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await PlannerService.createTodo(
        curriculumId: _curriculumId!,
        title: _title.text.trim(),
        dueDate: _selectedDate,
        priority: _priority,
      );
      _title.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 날짜에 투두를 추가했어.')),
      );
      setState(() {});
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _sameDay(DateTime a, String? ymd) {
    final b = DateTime.tryParse(ymd ?? '');
    if (b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DateTime> _monthDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final next = DateTime(month.year, month.month + 1, 1);
    final total = next.difference(first).inDays;
    return List.generate(total, (i) => DateTime(month.year, month.month, i + 1));
  }

  List<DateTime> _weekDays(DateTime day) {
    final monday = DateTime(day.year, day.month, day.day - (day.weekday - 1));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  Future<void> _cycleStatus(Map<String, dynamic> t) async {
    final now = (t['status'] ?? 'todo').toString();
    final next = now == 'todo' ? 'in_progress' : (now == 'in_progress' ? 'done' : 'todo');
    await PlannerService.setTodoStatus(todoId: t['id'] as String, status: next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next == 'in_progress' ? '진행 중으로 표시했어.' : next == 'done' ? '완료 처리했어.' : '대기 상태로 되돌렸어.')),
    );
    setState(() {});
  }

  String _fmt(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: Future.wait([
          PlannerService.listCurriculums(),
          PlannerService.listTodos(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final curriculums = snapshot.data![0];
          final todos = snapshot.data![1];
          final visibleDays = _viewMode == 'week' ? _weekDays(_selectedDate) : _monthDays(_displayMonth);
          final selectedTodos = todos.where((t) => _sameDay(_selectedDate, t['due_date'] as String?)).where((t) {
            if (_curriculumId == null) return true;
            return t['curriculum_id'] == _curriculumId;
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
            children: [
              Container(
                decoration: AppTheme.glassCard(highlight: true),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('실행 미션 보드', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
                    const SizedBox(height: 8),
                    const Text('투두 캘린더', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.lightText)),
                    const SizedBox(height: 10),
                    const Text(
                      '커리큘럼을 선택하면 캘린더를 중심으로 날짜별 투두를 확인하고 실행 상태를 관리할 수 있어.',
                      style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.lightMuted),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: _curriculumId,
                      items: curriculums
                          .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['title'] ?? '-')))
                          .toList(),
                      onChanged: (v) => setState(() => _curriculumId = v),
                      decoration: const InputDecoration(labelText: '표시할 커리큘럼 선택'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'month', label: Text('한달 보기')),
                              ButtonSegment(value: 'week', label: Text('일주일 보기')),
                            ],
                            selected: {_viewMode},
                            onSelectionChanged: (s) => setState(() => _viewMode = s.first),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() {
                            _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
                            _selectedDate = DateTime(_displayMonth.year, _displayMonth.month, 1);
                          }),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              _viewMode == 'week' ? '${_fmt(visibleDays.first)} ~ ${_fmt(visibleDays.last)}' : '${_displayMonth.year}년 ${_displayMonth.month}월',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
                            _selectedDate = DateTime(_displayMonth.year, _displayMonth.month, 1);
                          }),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: visibleDays.map((d) {
                          final dayTodos = todos.where((t) {
                            final same = _sameDay(d, t['due_date'] as String?);
                            final passCurr = _curriculumId == null || t['curriculum_id'] == _curriculumId;
                            return same && passCurr;
                          }).toList();
                          final selected = d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
                          return InkWell(
                            onTap: () => setState(() => _selectedDate = d),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: _viewMode == 'week' ? 150 : 82,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF0066FF) : Colors.white.withValues(alpha: 0.46),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${d.day}',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: selected ? Colors.white : AppColors.lightText),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    dayTodos.isEmpty ? '투두 없음' : '투두 ${dayTodos.length}개',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? Colors.white70 : AppColors.lightMuted),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: AppTheme.glassCard(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_fmt(_selectedDate)} 투두 리스트', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    TextField(controller: _title, decoration: const InputDecoration(labelText: '새 투두 제목')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _priority,
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('낮음')),
                        DropdownMenuItem(value: 'medium', child: Text('보통')),
                        DropdownMenuItem(value: 'high', child: Text('높음')),
                      ],
                      onChanged: (v) => setState(() => _priority = v ?? 'medium'),
                      decoration: const InputDecoration(labelText: '우선순위'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _create,
                        icon: const Icon(Icons.add_task_rounded),
                        label: Text(_saving ? '추가 중...' : '선택 날짜에 투두 추가'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (selectedTodos.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text('선택한 날짜에 등록된 투두가 없어.', style: TextStyle(color: AppColors.lightMuted)),
                      ),
                    ...selectedTodos.map((t) {
                      final status = (t['status'] ?? 'todo').toString();
                      final isProgress = status == 'in_progress';
                      final isDone = status == 'done';
                      return GestureDetector(
                        onTap: () => _cycleStatus(t),
                        child: Opacity(
                          opacity: isDone ? 0.48 : 1,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isProgress ? const Color(0xFF0066FF).withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.36),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isProgress ? const Color(0xFF0066FF) : Colors.white.withValues(alpha: 0.62),
                                width: isProgress ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? Colors.white.withValues(alpha: 0.42)
                                        : isProgress
                                            ? const Color(0xFF0066FF)
                                            : Colors.white.withValues(alpha: 0.52),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isDone ? Icons.check_rounded : isProgress ? Icons.play_arrow_rounded : Icons.radio_button_unchecked_rounded,
                                    color: isProgress ? Colors.white : AppColors.primaryStrong,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t['title'] ?? '-',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.lightText,
                                          decoration: isDone ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isDone ? '완료됨' : isProgress ? '진행 중 - 한 번 더 누르면 완료' : '대기 중 - 한 번 누르면 진행 중',
                                        style: const TextStyle(fontSize: 12, color: AppColors.lightMuted),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
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
