import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../services/planner_service.dart';

class GuidelinePage extends StatefulWidget {
  const GuidelinePage({super.key});

  @override
  State<GuidelinePage> createState() => _GuidelinePageState();
}

class _GuidelinePageState extends State<GuidelinePage> {
  final _role = TextEditingController(text: 'Flutter 개발자');
  final _title = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _role.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_role.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 직무를 입력해줘.')),
      );
      return;
    }
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가이드라인 제목을 입력해줘.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await PlannerService.createGuideline(
        role: _role.text.trim(),
        title: _title.text.trim(),
        notes: _notes.text.trim(),
      );
      _title.clear();
      _notes.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가이드라인을 생성했어.')),
      );
      setState(() {});
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: PlannerService.listGuidelines(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
            children: [
              Container(
                decoration: AppTheme.glassCard(highlight: true),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('학습 항로 설계', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
                    const SizedBox(height: 8),
                    const Text('가이드라인 빌더', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.lightText)),
                    const SizedBox(height: 10),
                    const Text(
                      '목표 직무와 학습 원칙을 먼저 정리해서, 이후 커리큘럼과 투두가 같은 방향으로 움직이게 만들어줘.',
                      style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.lightMuted),
                    ),
                    const SizedBox(height: 18),
                    TextField(controller: _role, decoration: const InputDecoration(labelText: '목표 직무')),
                    const SizedBox(height: 12),
                    TextField(controller: _title, decoration: const InputDecoration(labelText: '가이드라인 제목')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notes,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: '학습 원칙 / 메모',
                        hintText: '예: 주 5일 꾸준히, 실습 위주, 포트폴리오 중심',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _create,
                        icon: const Icon(Icons.flight_takeoff_rounded),
                        label: Text(_saving ? '생성 중...' : '가이드라인 생성하기'),
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
                        const Expanded(child: Text('내 가이드라인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('${items.length}개', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text('아직 생성된 가이드라인이 없어. 첫 학습 항로를 만들어보자.', style: TextStyle(color: AppColors.lightMuted)),
                      ),
                    ...items.map(
                      (e) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.36),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['title'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                            const SizedBox(height: 6),
                            Text(e['target_role'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepBlue)),
                            if ((e['notes'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(e['notes'], style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.lightMuted)),
                            ],
                          ],
                        ),
                      ),
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
