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
  final List<_SegmentDraft> _segmentDrafts = [];

  @override
  void dispose() {
    _roleCtrl.dispose();
    _guidelineTitleCtrl.dispose();
    _guidelineNotesCtrl.dispose();
    _curriculumTitleCtrl.dispose();
    for (final segment in _segmentDrafts) {
      segment.dispose();
    }
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

  String? _validateSegments() {
    DateTime previous = _start;
    for (final segment in _segmentDrafts) {
      if (segment.nameCtrl.text.trim().isEmpty) {
        return '분기점 구간 이름을 입력해줘.';
      }
      if (!segment.endDate.isAfter(previous)) {
        return '분기점 종료일은 이전 구간보다 뒤여야 해.';
      }
      if (segment.endDate.isAfter(_end)) {
        return '분기점 종료일은 전체 종료일보다 늦을 수 없어.';
      }
      previous = segment.endDate;
    }
    return null;
  }

  void _addSegment() {
    setState(() {
      _segmentDrafts.add(
        _SegmentDraft(
          color: PlannerService.segmentPalette[_segmentDrafts.length % PlannerService.segmentPalette.length],
          endDate: _segmentDrafts.isEmpty ? _start.add(const Duration(days: 7)) : _segmentDrafts.last.endDate.add(const Duration(days: 7)),
        ),
      );
    });
  }

  void _removeSegment(int index) {
    setState(() {
      _segmentDrafts[index].dispose();
      _segmentDrafts.removeAt(index);
    });
  }

  Future<void> _pickSegmentDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: _start,
      lastDate: _end,
      initialDate: _segmentDrafts[index].endDate,
    );
    if (picked != null) {
      setState(() => _segmentDrafts[index].endDate = picked);
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
    final validationError = _validateSegments();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }
    setState(() => _savingCurriculum = true);
    try {
      await PlannerService.createCurriculum(
        guidelineId: guidelineId,
        title: _curriculumTitleCtrl.text.trim(),
        start: _start,
        end: _end,
        segments: _segmentDrafts.asMap().entries.map((entry) => entry.value.toJson(entry.key)).toList(),
      );
      _curriculumTitleCtrl.clear();
      for (final segment in _segmentDrafts) {
        segment.dispose();
      }
      _segmentDrafts.clear();
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
                  segmentDrafts: _segmentDrafts,
                  onAddSegment: _addSegment,
                  onRemoveSegment: _removeSegment,
                  onPickSegmentDate: _pickSegmentDate,
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
  final List<_SegmentDraft> segmentDrafts;
  final VoidCallback onAddSegment;
  final void Function(int index) onRemoveSegment;
  final Future<void> Function(int index) onPickSegmentDate;

  const _CurriculumPanel({
    required this.selectedCurriculum,
    required this.linkedGuideline,
    required this.curriculumTodos,
    required this.progress,
    required this.completedTodos,
    required this.titleCtrl,
    required this.start,
    required this.end,
    required this.saving,
    required this.onCreate,
    required this.onPickStart,
    required this.onPickEnd,
    required this.fmt,
    required this.segmentDrafts,
    required this.onAddSegment,
    required this.onRemoveSegment,
    required this.onPickSegmentDate,
  });

  @override
  Widget build(BuildContext context) {
    final currentSegments = selectedCurriculum == null ? const <Map<String, dynamic>>[] : PlannerService.buildCurriculumSegments(selectedCurriculum!);

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
              _VerticalTimelineDateCard(label: '시작일', value: fmt(start), onTap: onPickStart),
              const SizedBox(height: 10),
              ...List.generate(segmentDrafts.length, (index) {
                final segment = segmentDrafts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SegmentDraftCard(
                    index: index,
                    colorHex: segment.color,
                    nameCtrl: segment.nameCtrl,
                    endDateLabel: fmt(segment.endDate),
                    onPickDate: () => onPickSegmentDate(index),
                    onRemove: () => onRemoveSegment(index),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(onPressed: onAddSegment, icon: const Icon(Icons.add_circle_rounded), label: const Text('분기점 추가')),
              ),
              const SizedBox(height: 4),
              _VerticalTimelineDateCard(label: '종료일', value: fmt(end), onTap: onPickEnd),
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
                if (currentSegments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('현재 구간', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ...currentSegments.map((segment) => _SegmentOverviewCard(segment: segment)),
                ],
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

class _VerticalTimelineDateCard extends StatelessWidget {
  final String label;
  final String value;
  final Future<void> Function() onTap;
  const _VerticalTimelineDateCard({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 14, height: 14, decoration: const BoxDecoration(color: AppColors.primaryStrong, shape: BoxShape.circle)),
            Container(width: 2, height: 56, color: AppColors.primaryStrong.withValues(alpha: 0.25)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(child: _DateCard(label: label, value: value, onTap: onTap)),
      ],
    );
  }
}

class _SegmentDraftCard extends StatelessWidget {
  final int index;
  final String colorHex;
  final TextEditingController nameCtrl;
  final String endDateLabel;
  final VoidCallback onPickDate;
  final VoidCallback onRemove;

  const _SegmentDraftCard({required this.index, required this.colorHex, required this.nameCtrl, required this.endDateLabel, required this.onPickDate, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(colorHex));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            Container(width: 2, height: 110, color: color.withValues(alpha: 0.25)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.34), borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('분기점 ${index + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                    const Spacer(),
                    IconButton(onPressed: onRemove, icon: const Icon(Icons.close_rounded, size: 18)),
                  ],
                ),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '구간 이름')),
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: onPickDate, icon: const Icon(Icons.event_rounded), label: Text('분기점 종료일 $endDateLabel')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SegmentOverviewCard extends StatelessWidget {
  final Map<String, dynamic> segment;
  const _SegmentOverviewCard({required this.segment});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse((segment['color'] ?? PlannerService.segmentPalette.first).toString()));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(segment['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800))),
          Text('${segment['start_date']} ~ ${segment['end_date']}', style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
        ],
      ),
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

class _SegmentDraft {
  final TextEditingController nameCtrl = TextEditingController();
  DateTime endDate;
  final String color;

  _SegmentDraft({required this.color, required this.endDate});

  Map<String, dynamic> toJson(int order) => {
        'id': 'segment-$order-${DateTime.now().microsecondsSinceEpoch}',
        'name': nameCtrl.text.trim(),
        'end_date': endDate.toIso8601String().substring(0, 10),
        'order': order,
        'color': color,
      };

  void dispose() {
    nameCtrl.dispose();
  }
}
