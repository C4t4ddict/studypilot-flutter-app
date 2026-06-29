import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          final selectedCurriculum = _curriculumId == null
              ? null
              : (curriculums.where((c) => c['id'] == _curriculumId).isEmpty
                  ? null
                  : curriculums.firstWhere((c) => c['id'] == _curriculumId));
          final curriculumTodos = todos.where((t) {
            if (_curriculumId == null) return true;
            return t['curriculum_id'] == _curriculumId;
          }).toList();
          final selectedTodos = curriculumTodos.where((t) => _sameDay(_selectedDate, t['due_date'] as String?)).toList();
          final totalCount = curriculumTodos.length;
          final doneCount = curriculumTodos.where((t) => (t['status'] ?? 'todo') == 'done').length;
          final progressCount = curriculumTodos.where((t) => (t['status'] ?? 'todo') == 'in_progress').length;
          final todoCount = curriculumTodos.where((t) => (t['status'] ?? 'todo') == 'todo').length;
          final weekTodos = curriculumTodos.where((t) => visibleDays.any((d) => _sameDay(d, t['due_date'] as String?))).toList();
          final today = DateTime.now();
          final todayTodos = curriculumTodos.where((t) => _sameDay(today, t['due_date'] as String?)).toList();
          final overdueTodos = curriculumTodos.where((t) {
            final due = DateTime.tryParse((t['due_date'] ?? '').toString());
            if (due == null) return false;
            final status = (t['status'] ?? 'todo').toString();
            return DateTime(due.year, due.month, due.day).isBefore(DateTime(today.year, today.month, today.day)) && status != 'done';
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.checklist_rounded, color: AppColors.primaryStrong),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '이 단계에서는 커리큘럼을 선택한 뒤 날짜별 투두를 실제 실행 단위로 굴리면 돼.',
                              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.lightText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.48)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('투두 캘린더의 역할', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                          SizedBox(height: 8),
                          Text('• 오늘/이번 주에 실제로 해야 할 실행 항목을 관리해', style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.lightMuted)),
                          Text('• 날짜별 투두 추가와 상태 변경, 우선순위 확인에 더 집중해', style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.lightMuted)),
                          Text('• 큰 흐름 확인은 학습 캘린더, 실행 체크는 여기서 하는 구조야', style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.lightMuted)),
                        ],
                      ),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCurriculum == null ? '전체 커리큘럼 실행 요약' : '선택 커리큘럼 실행 요약',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.lightText),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedCurriculum == null
                                ? '커리큘럼을 고르면 해당 학습 항로의 실행 현황을 더 또렷하게 볼 수 있어.'
                                : '${selectedCurriculum['title'] ?? '-'} 기준으로 실행 현황을 보고 있어.',
                            style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.lightMuted),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _SummaryChip(label: '전체', value: '$totalCount개'),
                              _SummaryChip(label: '완료', value: '$doneCount개'),
                              _SummaryChip(label: '진행중', value: '$progressCount개'),
                              _SummaryChip(label: '대기', value: '$todoCount개'),
                              _SummaryChip(label: _viewMode == 'week' ? '이번 주' : '이번 달', value: '${weekTodos.length}개'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/calendar'),
                              icon: const Icon(Icons.route_rounded),
                              label: const Text('학습 캘린더로 큰 흐름 보기'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (todayTodos.isNotEmpty || overdueTodos.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('실행 리마인드', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                            const SizedBox(height: 8),
                            Text(
                              overdueTodos.isNotEmpty
                                  ? '밀린 일정 ${overdueTodos.length}개가 있어. 오늘 일정 전에 먼저 정리해두는 게 좋아.'
                                  : '오늘 일정 ${todayTodos.length}개가 잡혀 있어. 지금 바로 하나씩 진행해보자.',
                              style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.lightMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
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

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightText)),
        ],
      ),
    );
  }
}
