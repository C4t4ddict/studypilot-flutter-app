import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_theme.dart';
import '../../core/theme_controller.dart';
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
  bool _sidebarExpanded = false;

  final _newTodoCtrl = TextEditingController();
  String _newTodoPriority = 'medium';
  final Set<String> _selectedTodoIds = {};
  String? _curriculumId;

  @override
  void initState() {
    super.initState();
    if (widget.initialView == 'week' || widget.initialView == 'month') {
      _viewMode = widget.initialView!;
    }
    if (['all', 'todo', 'in_progress', 'done'].contains(widget.initialFilter)) {
      _todoFilter = widget.initialFilter!;
    }
    final d = DateTime.tryParse(widget.initialDate ?? '');
    if (d != null) {
      _selected = DateTime(d.year, d.month, d.day);
      _displayMonth = DateTime(d.year, d.month, 1);
    }
  }

  @override
  void dispose() {
    _newTodoCtrl.dispose();
    super.dispose();
  }

  String _sharePath() {
    final ymd = _selected.toIso8601String().substring(0, 10);
    return '/calendar?view=$_viewMode&filter=$_todoFilter&date=$ymd';
  }

  void _syncUrl() => context.replace(_sharePath());

  Future<void> _copyShareLink() async {
    final absolute = kIsWeb ? '${Uri.base.origin}${_sharePath()}' : _sharePath();
    await Clipboard.setData(ClipboardData(text: absolute));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공유 링크 복사 완료')),
    );
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

  bool _isInRange(DateTime day, String? start, String? end) {
    if (start == null || end == null) return false;
    final s = DateTime.tryParse(start);
    final e = DateTime.tryParse(end);
    if (s == null || e == null) return false;
    final d = DateTime(day.year, day.month, day.day);
    final ds = DateTime(s.year, s.month, s.day);
    final de = DateTime(e.year, e.month, e.day);
    return !d.isBefore(ds) && !d.isAfter(de);
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

  bool _todoPass(Map<String, dynamic> t) {
    final s = (t['status'] ?? 'todo').toString();
    if (_todoFilter == 'all') return true;
    return s == _todoFilter;
  }

  Future<void> _addTodo() async {
    if (_curriculumId == null || _newTodoCtrl.text.trim().isEmpty) return;
    await PlannerService.createTodo(
      curriculumId: _curriculumId!,
      title: _newTodoCtrl.text.trim(),
      dueDate: _selected,
      priority: _newTodoPriority,
    );
    _newTodoCtrl.clear();
    if (mounted) setState(() {});
  }

  Future<void> _bulkMoveSelectedTodos() async {
    if (_selectedTodoIds.isEmpty) return;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _selected,
    );
    if (picked == null) return;
    await PlannerService.moveTodosDueDate(todoIds: _selectedTodoIds.toList(), dueDate: picked);
    if (mounted) {
      setState(() => _selectedTodoIds.clear());
    }
  }

  Future<void> _changePriority(Map<String, dynamic> t) async {
    final cur = (t['priority'] ?? 'medium').toString();
    final next = cur == 'low' ? 'medium' : (cur == 'medium' ? 'high' : 'low');
    await PlannerService.updateTodoPriority(todoId: t['id'] as String, priority: next);
    if (mounted) setState(() {});
  }

  Future<void> _deleteTodo(String id) async {
    await PlannerService.deleteTodo(todoId: id);
    if (mounted) setState(() {});
  }

  Future<void> _editTodoTitle(Map<String, dynamic> t) async {
    final ctrl = TextEditingController(text: (t['title'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('투두 수정'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '제목')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('저장')),
        ],
      ),
    );
    if (ok == true) {
      await PlannerService.updateTodoTitle(todoId: t['id'] as String, title: ctrl.text);
      if (mounted) setState(() {});
    }
  }

  Future<void> _changeDueDate(String todoId) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _selected,
    );
    if (picked == null) return;
    await PlannerService.updateTodoDueDate(todoId: todoId, dueDate: picked);
    if (mounted) setState(() {});
  }

  Future<void> _cycleTodoStatus(Map<String, dynamic> t) async {
    final now = (t['status'] ?? 'todo').toString();
    final next = now == 'todo' ? 'in_progress' : (now == 'in_progress' ? 'done' : 'todo');
    await PlannerService.setTodoStatus(todoId: t['id'] as String, status: next);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder(
      future: Future.wait([PlannerService.listCurriculums(), PlannerService.listTodos()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final curriculums = snapshot.data![0];
        final todos = snapshot.data![1];

        final visibleDays = _viewMode == 'week' ? _weekDays(_selected) : _monthDays(_displayMonth);
        final selectedTodos = todos.where((t) => _isSameDay(_selected, t['due_date'] as String?)).where(_todoPass).toList();

        final isWide = MediaQuery.of(context).size.width >= 1100;
        final currentPath = GoRouterState.of(context).matchedLocation;

        final selectedCurriculum = _curriculumId == null
            ? null
            : curriculums.cast<Map<String, dynamic>>().where((c) => c['id'] == _curriculumId).cast<Map<String, dynamic>?>().firstOrNull;

        final menuPanel = _MenuPanel(
          expanded: _sidebarExpanded,
          currentPath: currentPath,
          onGo: (path) => context.go(path),
          viewMode: _viewMode,
          todoFilter: _todoFilter,
          onViewChanged: (v) {
            setState(() => _viewMode = v);
            _syncUrl();
          },
          onFilterChanged: (f) {
            setState(() => _todoFilter = f);
            _syncUrl();
          },
        );

        final calendarPanel = _CalendarPanel(
          selected: _selected,
          displayMonth: _displayMonth,
          visibleDays: visibleDays,
          curriculums: curriculums,
          todos: todos,
          isInRange: _isInRange,
          isSameDay: _isSameDay,
          onSelectDay: (d) {
            setState(() {
              _selected = d;
              _displayMonth = DateTime(d.year, d.month, 1);
            });
            _syncUrl();
          },
          onPrevMonth: () {
            setState(() {
              _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
              _selected = DateTime(_displayMonth.year, _displayMonth.month, 1);
            });
            _syncUrl();
          },
          onNextMonth: () {
            setState(() {
              _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
              _selected = DateTime(_displayMonth.year, _displayMonth.month, 1);
            });
            _syncUrl();
          },
          todoPass: _todoPass,
          selectedCurriculum: selectedCurriculum,
          onCopyShare: _copyShareLink,
          onShare: _shareCurrentState,
          onQr: _showShareQr,
        );

        final todoPanel = _TodoPanel(
          selected: _selected,
          curriculums: curriculums,
          selectedTodos: selectedTodos,
          todoController: _newTodoCtrl,
          curriculumId: _curriculumId,
          newTodoPriority: _newTodoPriority,
          selectedTodoIds: _selectedTodoIds,
          onCurriculumChanged: (v) => setState(() => _curriculumId = v),
          onPriorityChanged: (p) => setState(() => _newTodoPriority = p),
          onToggleSelect: (id) {
            setState(() {
              if (_selectedTodoIds.contains(id)) {
                _selectedTodoIds.remove(id);
              } else {
                _selectedTodoIds.add(id);
              }
            });
          },
          onBulkMove: _bulkMoveSelectedTodos,
          onAddTodo: _addTodo,
          onCycleStatus: _cycleTodoStatus,
          onEdit: _editTodoTitle,
          onDelete: _deleteTodo,
          onChangeDueDate: _changeDueDate,
          onCyclePriority: _changePriority,
        );

        if (widget.embedded) {
          if (!isWide) {
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [calendarPanel, const SizedBox(height: 12), todoPanel],
            );
          }
          return Row(
            children: [
              Expanded(flex: 2, child: calendarPanel),
              const VerticalDivider(width: 1),
              Expanded(flex: 2, child: todoPanel),
            ],
          );
        }

        if (!isWide) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [menuPanel, const SizedBox(height: 12), calendarPanel, const SizedBox(height: 12), todoPanel],
          );
        }

        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: _sidebarExpanded ? 230 : 92,
              child: menuPanel,
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: calendarPanel,
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: todoPanel,
            ),
          ],
        );
      },
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('학습 캘린더'),
        leading: IconButton(
          icon: Icon(_sidebarExpanded ? Icons.menu_open : Icons.menu),
          onPressed: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
        ),
        actions: [
          IconButton(
            tooltip: '라이트/다크 전환',
            onPressed: toggleThemeMode,
            icon: Icon(themeModeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(tooltip: '링크 복사', onPressed: _copyShareLink, icon: const Icon(Icons.link)),
          IconButton(tooltip: 'QR 공유', onPressed: _showShareQr, icon: const Icon(Icons.qr_code)),
          IconButton(tooltip: '공유', onPressed: _shareCurrentState, icon: const Icon(Icons.share)),
        ],
      ),
      body: body,
    );
  }
}

class _MenuPanel extends StatelessWidget {
  final bool expanded;
  final String currentPath;
  final void Function(String) onGo;
  final String viewMode;
  final String todoFilter;
  final void Function(String) onViewChanged;
  final void Function(String) onFilterChanged;

  const _MenuPanel({
    required this.expanded,
    required this.currentPath,
    required this.onGo,
    required this.viewMode,
    required this.todoFilter,
    required this.onViewChanged,
    required this.onFilterChanged,
  });

  Widget _navIcon({required BuildContext context, required IconData icon, required String tooltip, required String path}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active = currentPath == path;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onGo(path),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: expanded ? double.infinity : 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? (dark ? Colors.white12 : const Color(0xFFDCE9FF)) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? const Color(0xFF7BA9FF) : (dark ? Colors.white12 : const Color(0xFFE2E7F4)),
            ),
          ),
          child: expanded
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: dark ? Colors.white : AppColors.deepBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(tooltip, style: TextStyle(color: dark ? Colors.white : AppColors.deepBlue, fontWeight: FontWeight.w700)),
                  ],
                )
              : Icon(icon, color: dark ? Colors.white : AppColors.deepBlue, size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF101625) : const Color(0xFFF2F6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _navIcon(context: context, icon: Icons.home_rounded, tooltip: '홈', path: '/'),
          const SizedBox(height: 10),
          _navIcon(context: context, icon: Icons.rule_rounded, tooltip: '가이드라인', path: '/guidelines'),
          const SizedBox(height: 10),
          _navIcon(context: context, icon: Icons.event_note_rounded, tooltip: '커리큘럼', path: '/curriculums'),
          const SizedBox(height: 10),
          _navIcon(context: context, icon: Icons.calendar_month_rounded, tooltip: '캘린더', path: '/calendar'),
          const SizedBox(height: 10),
          _navIcon(context: context, icon: Icons.checklist_rounded, tooltip: '투두', path: '/todos'),
          const SizedBox(height: 10),
          _navIcon(context: context, icon: Icons.search_rounded, tooltip: '검색', path: '/search'),
          const SizedBox(height: 14),
          Divider(color: dark ? const Color(0x33FFFFFF) : const Color(0x22000000), height: 1),
          if (expanded) ...[
            const SizedBox(height: 12),
            Icon(viewMode == 'week' ? Icons.view_week_rounded : Icons.calendar_view_month_rounded, color: dark ? Colors.white70 : const Color(0xFF5A4CA1), size: 18),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(value: 'month', label: Text('월')),
                ButtonSegment(value: 'week', label: Text('주')),
              ],
              selected: {viewMode},
              onSelectionChanged: (v) => onViewChanged(v.first),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: todoFilter,
              dropdownColor: dark ? const Color(0xFF171A22) : Colors.white,
              style: TextStyle(color: dark ? Colors.white : const Color(0xFF3E2D7A)),
              underline: const SizedBox.shrink(),
              iconEnabledColor: dark ? Colors.white70 : const Color(0xFF5A4CA1),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('전체')),
                DropdownMenuItem(value: 'todo', child: Text('미완료')),
                DropdownMenuItem(value: 'in_progress', child: Text('진행중')),
                DropdownMenuItem(value: 'done', child: Text('완료')),
              ],
              onChanged: (v) {
                if (v != null) onFilterChanged(v);
              },
            ),
          ],
          const Spacer(),
          _navIcon(context: context, icon: Icons.person_outline_rounded, tooltip: '마이페이지', path: '/profile'),
        ],
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  final DateTime selected;
  final DateTime displayMonth;
  final List<DateTime> visibleDays;
  final List<Map<String, dynamic>> curriculums;
  final List<Map<String, dynamic>> todos;
  final Map<String, dynamic>? selectedCurriculum;
  final bool Function(DateTime, String?, String?) isInRange;
  final bool Function(DateTime, String?) isSameDay;
  final bool Function(Map<String, dynamic>) todoPass;
  final void Function(DateTime) onSelectDay;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function() onCopyShare;
  final Future<void> Function() onShare;
  final Future<void> Function() onQr;

  const _CalendarPanel({
    required this.selected,
    required this.displayMonth,
    required this.visibleDays,
    required this.curriculums,
    required this.todos,
    required this.isInRange,
    required this.isSameDay,
    required this.onSelectDay,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.todoPass,
    required this.selectedCurriculum,
    required this.onCopyShare,
    required this.onShare,
    required this.onQr,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSummaryTodos = todos.where((t) => isSameDay(selected, t['due_date'] as String?)).where(todoPass).toList();
    final completed = selectedSummaryTodos.where((t) => (t['status'] ?? 'todo') == 'done').length;
    final progress = selectedSummaryTodos.isEmpty ? 0.0 : completed / selectedSummaryTodos.length;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('학습 캘린더', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      selectedCurriculum == null
                          ? '커리큘럼을 선택하면 학습 항로가 더 또렷하게 보여.'
                          : '선택 커리큘럼: ${selectedCurriculum!['title'] ?? '-'}',
                      style: const TextStyle(fontSize: 13, color: AppColors.lightMuted),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: onCopyShare, icon: const Icon(Icons.link_rounded)),
              IconButton(onPressed: onQr, icon: const Icon(Icons.qr_code_rounded)),
              IconButton(onPressed: onShare, icon: const Icon(Icons.share_rounded)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.route_rounded, color: AppColors.primaryStrong),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '학습 캘린더는 커리큘럼 전체 항로와 진행 흐름을 보는 화면이야. 큰 일정 흐름과 선택 날짜의 학습 밀도를 확인하는 데 집중해.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.lightText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${selected.year}.${selected.month.toString().padLeft(2, '0')}.${selected.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('선택 날짜 일정 ${selectedSummaryTodos.length}개 · 완료 $completed개', style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(999)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(onPressed: onPrevMonth, icon: const Icon(Icons.chevron_left_rounded)),
              Expanded(
                child: Text(
                  '${displayMonth.year}년 ${displayMonth.month}월',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(onPressed: onNextMonth, icon: const Icon(Icons.chevron_right_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visibleDays.map((d) {
                  final cCount = curriculums.where((c) => isInRange(d, c['start_date'] as String?, c['end_date'] as String?)).length;
                  final dayTodos = todos.where((t) => isSameDay(d, t['due_date'] as String?)).where(todoPass).toList();
                  final tCount = dayTodos.length;
                  final doneCount = dayTodos.where((t) => (t['status'] ?? 'todo') == 'done').length;
                  final doneRatio = tCount == 0 ? 0.0 : (doneCount / tCount);
                  final has = cCount + tCount > 0;
                  final selectedDay = selected.year == d.year && selected.month == d.month && selected.day == d.day;

                  return Tooltip(
                    message: '${d.toIso8601String().substring(0, 10)}\n커리큘럼 $cCount / 투두 $tCount',
                    child: InkWell(
                      onTap: () => onSelectDay(d),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 58,
                        height: 64,
                        decoration: BoxDecoration(
                          color: selectedDay ? const Color(0xFF0066FF) : Colors.white.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: has ? const Color(0xFF0066FF).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: selectedDay ? Colors.white : AppColors.lightText,
                                ),
                              ),
                            ),
                            if (has)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                                  child: Text('${cCount + tCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            if (tCount > 0)
                              Positioned(
                                left: 6,
                                right: 6,
                                bottom: 6,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(value: doneRatio, minHeight: 4),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoPanel extends StatelessWidget {
  final DateTime selected;
  final List<Map<String, dynamic>> curriculums;
  final List<Map<String, dynamic>> selectedTodos;
  final TextEditingController todoController;
  final String? curriculumId;
  final String newTodoPriority;
  final Set<String> selectedTodoIds;
  final void Function(String?) onCurriculumChanged;
  final void Function(String) onPriorityChanged;
  final void Function(String) onToggleSelect;
  final Future<void> Function() onBulkMove;
  final Future<void> Function() onAddTodo;
  final Future<void> Function(Map<String, dynamic>) onCycleStatus;
  final Future<void> Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(String) onChangeDueDate;
  final Future<void> Function(Map<String, dynamic>) onCyclePriority;

  const _TodoPanel({
    required this.selected,
    required this.curriculums,
    required this.selectedTodos,
    required this.todoController,
    required this.curriculumId,
    required this.newTodoPriority,
    required this.selectedTodoIds,
    required this.onCurriculumChanged,
    required this.onPriorityChanged,
    required this.onToggleSelect,
    required this.onBulkMove,
    required this.onAddTodo,
    required this.onCycleStatus,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeDueDate,
    required this.onCyclePriority,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: AppTheme.glassCard(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('선택 날짜 투두 · ${selected.toIso8601String().substring(0, 10)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: curriculumId,
              items: curriculums
                  .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['title'] ?? '-')))
                  .toList(),
              onChanged: onCurriculumChanged,
              decoration: const InputDecoration(labelText: '연결 커리큘럼'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: todoController,
                    decoration: const InputDecoration(labelText: '새 투두'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(onPressed: onAddTodo, icon: const Icon(Icons.add_circle), label: const Text('추가')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: newTodoPriority,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('낮음')),
                      DropdownMenuItem(value: 'medium', child: Text('보통')),
                      DropdownMenuItem(value: 'high', child: Text('높음')),
                    ],
                    onChanged: (v) {
                      if (v != null) onPriorityChanged(v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text('선택 ${selectedTodoIds.length}개'),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: selectedTodoIds.isEmpty ? null : onBulkMove, child: const Text('선택 이동')),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: selectedTodos.isEmpty
                  ? const Center(child: Text('선택한 날짜에 등록된 투두가 없어.'))
                  : ListView.builder(
                      itemCount: selectedTodos.length,
                      itemBuilder: (_, i) {
                        final t = selectedTodos[i];
                        final id = t['id'] as String;
                        final status = (t['status'] ?? 'todo').toString();
                        final pr = (t['priority'] ?? 'medium').toString();
                        final done = status == 'done';
                        final inProgress = status == 'in_progress';
                        return Opacity(
                          opacity: done ? 0.52 : 1,
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            color: inProgress ? const Color(0xFFDCE9FF) : Colors.white.withValues(alpha: 0.45),
                            child: CheckboxListTile(
                              value: selectedTodoIds.contains(id),
                              onChanged: (_) => onToggleSelect(id),
                              title: Text(
                                t['title'] ?? '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  decoration: done ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Text('상태: $status · 우선순위: $pr · 마감: ${t['due_date'] ?? '-'}'),
                              secondary: InkWell(
                                onTap: () => onCycleStatus(t),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: inProgress ? const Color(0xFF0066FF) : Colors.white.withValues(alpha: 0.4),
                                  ),
                                  child: Icon(
                                    done ? Icons.check_rounded : inProgress ? Icons.play_arrow_rounded : Icons.radio_button_unchecked_rounded,
                                    color: inProgress ? Colors.white : AppColors.primaryStrong,
                                  ),
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
