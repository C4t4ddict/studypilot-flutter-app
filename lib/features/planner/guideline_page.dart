import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/planner_service.dart';

class GuidelinePage extends StatefulWidget {
  const GuidelinePage({super.key});

  @override
  State<GuidelinePage> createState() => _GuidelinePageState();
}

class _GoalBlock {
  final TextEditingController big = TextEditingController();
  final TextEditingController mid = TextEditingController();
  final TextEditingController small = TextEditingController();

  void dispose() {
    big.dispose();
    mid.dispose();
    small.dispose();
  }

  Map<String, String> toJson() => {
        'big': big.text.trim(),
        'mid': mid.text.trim(),
        'small': small.text.trim(),
      };
}

class _GuidelinePageState extends State<GuidelinePage> {
  final _role = TextEditingController(text: 'Flutter Developer');
  final _title = TextEditingController();
  final _goalSummary = TextEditingController();
  DateTime? _start;
  DateTime? _end;

  final List<_GoalBlock> _blocks = [_GoalBlock()];

  @override
  void dispose() {
    _role.dispose();
    _title.dispose();
    _goalSummary.dispose();
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: isStart
          ? (_start ?? DateTime.now())
          : (_end ?? _start ?? DateTime.now().add(const Duration(days: 30))),
    );
    if (d == null) return;
    setState(() {
      if (isStart) {
        _start = d;
        if (_end != null && _end!.isBefore(_start!)) _end = _start;
      } else {
        _end = d;
      }
    });
  }

  Future<void> _create() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('가이드라인 제목을 입력해주세요.')));
      return;
    }

    final payload = {
      'period': {
        'start': _start?.toIso8601String().substring(0, 10),
        'end': _end?.toIso8601String().substring(0, 10),
      },
      'goal_summary': _goalSummary.text.trim(),
      'goal_blocks': _blocks.map((b) => b.toJson()).toList(),
    };

    await PlannerService.createGuideline(
      role: _role.text.trim(),
      title: _title.text.trim(),
      notes: jsonEncode(payload),
    );

    _title.clear();
    _goalSummary.clear();
    _start = null;
    _end = null;
    for (final b in _blocks) {
      b.dispose();
    }
    _blocks
      ..clear()
      ..add(_GoalBlock());

    if (mounted) setState(() {});
  }

  Future<void> _generateCurriculumDraft(Map<String, dynamic> g) async {
    final id = (g['id'] ?? '').toString();
    if (id.isEmpty) return;

    Map<String, dynamic> meta = {};
    try {
      meta =
          jsonDecode((g['notes'] ?? '{}').toString()) as Map<String, dynamic>;
    } catch (_) {}

    final period = (meta['period'] as Map?) ?? {};
    DateTime start =
        DateTime.tryParse((period['start'] ?? '').toString()) ?? DateTime.now();
    DateTime end = DateTime.tryParse((period['end'] ?? '').toString()) ??
        start.add(const Duration(days: 27));
    if (end.isBefore(start)) end = start;

    final blocks = ((meta['goal_blocks'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    final days = end.difference(start).inDays + 1;
    final weeks = ((days + 6) ~/ 7).clamp(1, 52);

    for (int i = 0; i < weeks; i++) {
      final ws = start.add(Duration(days: i * 7));
      final we = ws.add(const Duration(days: 6)).isAfter(end)
          ? end
          : ws.add(const Duration(days: 6));

      String focus = '학습 목표';
      if (blocks.isNotEmpty) {
        final b = blocks[i % blocks.length];
        focus = (b['mid'] ?? b['big'] ?? b['small'] ?? '학습 목표').toString();
        if (focus.trim().isEmpty) focus = '학습 목표';
      }

      await PlannerService.createCurriculum(
        guidelineId: id,
        title: 'Week ${i + 1} · $focus',
        start: ws,
        end: we,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('커리큘럼 초안 $weeks개 자동 생성 완료')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1) Guideline Builder')),
      body: FutureBuilder(
        future: PlannerService.listGuidelines(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('새로운 가이드라인 생성',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _role,
                    decoration: const InputDecoration(
                      labelText: '지원 직무',
                      hintText: '예) Flutter 앱 개발자 / 프론트엔드 개발자',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: '가이드라인 제목',
                      hintText: '예) 12주 Flutter 취업 준비 로드맵',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickDate(isStart: true),
                          child: Text(
                            '시작일: ${_start == null ? '선택' : _start!.toIso8601String().substring(0, 10)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickDate(isStart: false),
                          child: Text(
                            '종료일: ${_end == null ? '선택' : _end!.toIso8601String().substring(0, 10)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _goalSummary,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '핵심 목표 요약',
                      hintText: '예) 3개월 내 포트폴리오 2개 + 면접 대비 + 이력서 완성',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('세부 가이드라인 (대목표/중목표/소목표)',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ..._blocks.asMap().entries.map((entry) {
                    final i = entry.key;
                    final b = entry.value;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('목표 블록 ${i + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                const Spacer(),
                                if (_blocks.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      setState(() {
                                        _blocks.removeAt(i).dispose();
                                      });
                                    },
                                  ),
                              ],
                            ),
                            TextField(
                              controller: b.big,
                              decoration: const InputDecoration(
                                labelText: '대목표',
                                hintText: '이루고 싶은 전체 목표 (예: 취업 포트폴리오 완성)',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: b.mid,
                              decoration: const InputDecoration(
                                labelText: '중목표',
                                hintText: '대목표 하위 목표 (예: 프로젝트 2개 제작, 이력서 개선)',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: b.small,
                              decoration: const InputDecoration(
                                labelText: '소목표',
                                hintText:
                                    '더 작은 시간 단위 실행 목표 (예: 이번 주 API 연동 완료)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _blocks.add(_GoalBlock())),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('목표 블록 추가'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: _create, child: const Text('가이드라인 생성')),
                  const Divider(height: 28),
                  const Text('생성된 가이드라인',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...items.map((e) {
                    String sub = '${e['target_role'] ?? '-'}';
                    try {
                      final m = jsonDecode((e['notes'] ?? '{}').toString())
                          as Map<String, dynamic>;
                      final p = (m['period'] as Map?) ?? {};
                      final s = (p['start'] ?? '-').toString();
                      final en = (p['end'] ?? '-').toString();
                      final sum = (m['goal_summary'] ?? '').toString();
                      sub = '${e['target_role'] ?? '-'} · $s ~ $en\n$sum';
                    } catch (_) {}
                    return Card(
                      child: ListTile(
                        title: Text(e['title'] ?? '-'),
                        subtitle: Text(sub),
                        trailing: TextButton.icon(
                          onPressed: () => _generateCurriculumDraft(e),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('커리큘럼 초안 생성'),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
