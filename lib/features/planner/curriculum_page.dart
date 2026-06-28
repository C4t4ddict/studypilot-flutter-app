import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../services/planner_service.dart';

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<CurriculumPage> createState() => _CurriculumPageState();
}

class _CurriculumPageState extends State<CurriculumPage> {
  String? _guidelineId;
  final _title = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 28));
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_guidelineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 가이드라인을 선택해줘.')),
      );
      return;
    }
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('커리큘럼 제목을 입력해줘.')),
      );
      return;
    }
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료일은 시작일보다 뒤여야 해.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await PlannerService.createCurriculum(
        guidelineId: _guidelineId!,
        title: _title.text.trim(),
        start: _start,
        end: _end,
      );
      _title.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('커리큘럼을 생성했어.')),
      );
      setState(() {});
    } finally {
      if (mounted) setState(() => _saving = false);
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
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final guidelines = snapshot.data![0];
          final curriculums = snapshot.data![1];

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
            children: [
              Container(
                decoration: AppTheme.glassCard(highlight: true),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('비행 계획 설계', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
                    const SizedBox(height: 8),
                    const Text('커리큘럼 플래너', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.lightText)),
                    const SizedBox(height: 10),
                    const Text(
                      '가이드라인을 선택하고 학습 기간을 정해서, 일정이 보이는 실제 커리큘럼으로 연결해줘.',
                      style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.lightMuted),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: _guidelineId,
                      items: guidelines
                          .map<DropdownMenuItem<String>>((g) => DropdownMenuItem(value: g['id'] as String, child: Text(g['title'] ?? '-')))
                          .toList(),
                      onChanged: (v) => setState(() => _guidelineId = v),
                      decoration: const InputDecoration(labelText: '연결할 가이드라인'),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _title, decoration: const InputDecoration(labelText: '커리큘럼 제목')),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _DateCard(
                            label: '시작일',
                            value: _fmt(_start),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDate: _start,
                              );
                              if (d != null) setState(() => _start = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateCard(
                            label: '종료일',
                            value: _fmt(_end),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDate: _end,
                              );
                              if (d != null) setState(() => _end = d);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flight_rounded, color: AppColors.primaryStrong),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '총 ${(_end.difference(_start).inDays + 1).clamp(1, 999)}일 일정으로 항로를 설계하고 있어.',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _create,
                        icon: const Icon(Icons.map_rounded),
                        label: Text(_saving ? '생성 중...' : '커리큘럼 생성하기'),
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
                    const Text('다음 단계로 이어가기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    const Text(
                      '커리큘럼이 준비됐으면 이제 날짜별 실행 단위인 투두로 내려가서 실제 학습을 굴릴 수 있어.',
                      style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.lightMuted),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/todos'),
                        icon: const Icon(Icons.checklist_rounded),
                        label: const Text('투두 캘린더로 이동'),
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
                    Row(
                      children: [
                        const Expanded(child: Text('생성된 커리큘럼', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('${curriculums.length}개', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...curriculums.map(
                      (c) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.36),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['title'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                            const SizedBox(height: 8),
                            Text('${c['start_date']} ~ ${c['end_date']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepBlue)),
                            const SizedBox(height: 8),
                            Text('연결 가이드라인: ${((c['guidelines'] ?? {})['title'] ?? '-')}', style: const TextStyle(fontSize: 13, color: AppColors.lightMuted)),
                          ],
                        ),
                      ),
                    ),
                    if (curriculums.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text('아직 커리큘럼이 없어. 가이드라인을 바탕으로 첫 학습 일정을 만들어보자.', style: TextStyle(color: AppColors.lightMuted)),
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

class _DateCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateCard({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.36),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryStrong),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
