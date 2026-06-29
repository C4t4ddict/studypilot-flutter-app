import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../services/planner_service.dart';

class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  String _tab = 'guideline';
  String? _selectedCurriculumId;

  final _roleCtrl = TextEditingController(text: 'Flutter 개발자');
  final _guidelineTitleCtrl = TextEditingController();
  final _guidelineNotesCtrl = TextEditingController();
  final _curriculumTitleCtrl = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 28));
  bool _savingGuideline = false;
  bool _savingCurriculum = false;

  @override
  void dispose() {
    _roleCtrl.dispose();
    _guidelineTitleCtrl.dispose();
    _guidelineNotesCtrl.dispose();
    _curriculumTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _createGuideline() async {
    if (_roleCtrl.text.trim().isEmpty || _guidelineTitleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('목표 직무와 가이드라인 제목을 입력해줘.')));
      return;
    }
    setState(() => _savingGuideline = true);
    try {
      await PlannerService.createGuideline(
        role: _roleCtrl.text.trim(),
        title: _guidelineTitleCtrl.text.trim(),
        notes: _guidelineNotesCtrl.text.trim(),
      );
      _guidelineTitleCtrl.clear();
      _guidelineNotesCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가이드라인을 생성했어.')));
      setState(() {});
    } finally {
      if (mounted) setState(() => _savingGuideline = false);
    }
  }

  Future<void> _createCurriculum(String? guidelineId) async {
    if (guidelineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('먼저 연결할 가이드라인이 필요해.')));
      return;
    }
    if (_curriculumTitleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('커리큘럼 제목을 입력해줘.')));
      return;
    }
    setState(() => _savingCurriculum = true);
    try {
      await PlannerService.createCurriculum(
        guidelineId: guidelineId,
        title: _curriculumTitleCtrl.text.trim(),
        start: _start,
        end: _end,
      );
      _curriculumTitleCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('커리큘럼을 생성했어.')));
      setState(() {});
    } finally {
      if (mounted) setState(() => _savingCurriculum = false);
    }
  }

  String _fmt(DateTime date) => '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: Future.wait([
          PlannerService.listGuidelines(),
          PlannerService.listCurriculums(),
          PlannerService.listTodos(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final guidelines = snapshot.data![0];
          final curriculums = snapshot.data![1];
          final todos = snapshot.data![2];

          if (_selectedCurriculumId == null && curriculums.isNotEmpty) {
            _selectedCurriculumId = curriculums.first['id'] as String;
          }

          final selectedCurriculum = _selectedCurriculumId == null
              ? null
              : curriculums.cast<Map<String, dynamic>?>().firstWhere(
                    (c) => c?['id'] == _selectedCurriculumId,
                    orElse: () => curriculums.isNotEmpty ? curriculums.first : null,
                  );

          final linkedGuideline = selectedCurriculum == null
              ? null
              : guidelines.cast<Map<String, dynamic>?>().firstWhere(
                    (g) => g?['id'] == selectedCurriculum['guideline_id'],
                    orElse: () => null,
                  );

          final curriculumTodos = selectedCurriculum == null
              ? <Map<String, dynamic>>[]
              : todos.where((t) => t['curriculum_id'] == selectedCurriculum['id']).toList();
          final completedTodos = curriculumTodos.where((t) => (t['status'] ?? 'todo') == 'done').length;
          final progress = curriculumTodos.isEmpty ? 0.0 : completedTodos / curriculumTodos.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
            children: [
              Container(
                decoration: AppTheme.glassCard(highlight: true),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('학습', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.lightText)),
                    const SizedBox(height: 8),
                    const Text('현재 선택한 학습 흐름을 관리해', style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.lightMuted)),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.36),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCurriculumId,
                        items: curriculums
                            .map((c) => DropdownMenuItem<String>(value: c['id'] as String, child: Text(c['title'] ?? '-')))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCurriculumId = v),
                        decoration: const InputDecoration(border: InputBorder.none, labelText: '커리큘럼 선택'),
                        icon: const Icon(Icons.expand_more_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _LearningTabButton(label: '가이드라인', active: _tab == 'guideline', onTap: () => setState(() => _tab = 'guideline'))),
                          Expanded(child: _LearningTabButton(label: '커리큘럼', active: _tab == 'curriculum', onTap: () => setState(() => _tab = 'curriculum'))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_tab == 'guideline')
                _GuidelinePanel(
                  selectedCurriculum: selectedCurriculum,
                  linkedGuideline: linkedGuideline,
                  allGuidelines: guidelines,
                  roleCtrl: _roleCtrl,
                  titleCtrl: _guidelineTitleCtrl,
                  notesCtrl: _guidelineNotesCtrl,
                  saving: _savingGuideline,
                  onCreate: _createGuideline,
                )
              else
                _CurriculumPanel(
                  selectedCurriculum: selectedCurriculum,
                  linkedGuideline: linkedGuideline,
                  curriculumTodos: curriculumTodos,
                  progress: progress,
                  completedTodos: completedTodos,
                  titleCtrl: _curriculumTitleCtrl,
                  start: _start,
                  end: _end,
                  saving: _savingCurriculum,
                  onPickStart: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: _start);
                    if (d != null) setState(() => _start = d);
                  },
                  onPickEnd: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: _end);
                    if (d != null) setState(() => _end = d);
                  },
                  onCreate: () => _createCurriculum(linkedGuideline?['id'] as String?),
                  fmt: _fmt,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LearningTabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LearningTabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0x190066FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? AppColors.primaryStrong : AppColors.lightMuted)),
      ),
    );
  }
}

class _GuidelinePanel extends StatelessWidget {
  final Map<String, dynamic>? selectedCurriculum;
  final Map<String, dynamic>? linkedGuideline;
  final List<Map<String, dynamic>> allGuidelines;
  final TextEditingController roleCtrl;
  final TextEditingController titleCtrl;
  final TextEditingController notesCtrl;
  final bool saving;
  final Future<void> Function() onCreate;

  const _GuidelinePanel({required this.selectedCurriculum, required this.linkedGuideline, required this.allGuidelines, required this.roleCtrl, required this.titleCtrl, required this.notesCtrl, required this.saving, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: AppTheme.glassCard(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('새 가이드라인 작성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: '목표 직무')),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '가이드라인 제목')),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, minLines: 4, maxLines: 6, decoration: const InputDecoration(labelText: '학습 원칙 / 메모')),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: saving ? null : onCreate, icon: const Icon(Icons.add_circle_rounded), label: Text(saving ? '생성 중...' : '새 가이드라인 작성'))),
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
              const Text('가이드라인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (selectedCurriculum == null)
                const Text('먼저 커리큘럼을 선택해줘.', style: TextStyle(color: AppColors.lightMuted))
              else if (linkedGuideline == null)
                const Text('이 커리큘럼에 연결된 가이드라인이 아직 없어.', style: TextStyle(color: AppColors.lightMuted))
              else ...[
                _InfoCard(label: '연결된 가이드라인', value: linkedGuideline?['title'] ?? '-'),
                _InfoCard(label: '목표 직무', value: linkedGuideline?['target_role'] ?? '-'),
                _InfoCard(label: '학습 원칙 / 메모', value: (linkedGuideline?['notes'] ?? '').toString().isEmpty ? '아직 메모가 없어.' : linkedGuideline!['notes']),
              ],
              const SizedBox(height: 18),
              const Text('관련 가이드라인 목록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...allGuidelines.take(3).map((e) => _InfoCard(label: e['title'] ?? '-', value: e['target_role'] ?? '-')),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurriculumPanel extends StatelessWidget {
  final Map<String, dynamic>? selectedCurriculum;
  final Map<String, dynamic>? linkedGuideline;
  final List<Map<String, dynamic>> curriculumTodos;
  final double progress;
  final int completedTodos;
  final TextEditingController titleCtrl;
  final DateTime start;
  final DateTime end;
  final bool saving;
  final Future<void> Function() onCreate;
  final Future<void> Function() onPickStart;
  final Future<void> Function() onPickEnd;
  final String Function(DateTime) fmt;

  const _CurriculumPanel({required this.selectedCurriculum, required this.linkedGuideline, required this.curriculumTodos, required this.progress, required this.completedTodos, required this.titleCtrl, required this.start, required this.end, required this.saving, required this.onCreate, required this.onPickStart, required this.onPickEnd, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: AppTheme.glassCard(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('새 커리큘럼 작성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '커리큘럼 제목')),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _DateCard(label: '시작일', value: fmt(start), onTap: onPickStart)),
                  const SizedBox(width: 12),
                  Expanded(child: _DateCard(label: '종료일', value: fmt(end), onTap: onPickEnd)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: saving ? null : onCreate, icon: const Icon(Icons.map_rounded), label: Text(saving ? '생성 중...' : '새 커리큘럼 작성'))),
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
              const Text('커리큘럼', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (selectedCurriculum == null)
                const Text('먼저 커리큘럼을 선택해줘.', style: TextStyle(color: AppColors.lightMuted))
              else ...[
                _InfoCard(label: '커리큘럼 제목', value: selectedCurriculum?['title'] ?? '-'),
                _InfoCard(label: '연결된 가이드라인', value: linkedGuideline?['title'] ?? '연결 안 됨'),
                _InfoCard(label: '기간', value: '${selectedCurriculum?['start_date'] ?? '-'} ~ ${selectedCurriculum?['end_date'] ?? '-'}'),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress, minHeight: 10, borderRadius: BorderRadius.circular(999)),
                const SizedBox(height: 8),
                Text('완료 $completedTodos / 전체 ${curriculumTodos.length}', style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final String value;
  final Future<void> Function() onTap;
  const _DateCard({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.34), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightText)),
        ]),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.34), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightText)),
      ]),
    );
  }
}
