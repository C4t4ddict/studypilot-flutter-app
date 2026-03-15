import 'package:flutter/material.dart';

import '../../services/planner_service.dart';

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<CurriculumPage> createState() => _CurriculumPageState();
}

class _CurriculumPageState extends State<CurriculumPage> {
  String? _roadmapId;
  final _title = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 28));

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_roadmapId == null) return;
    await PlannerService.createCurriculum(
      roadmapId: _roadmapId!,
      title: _title.text.trim(),
      start: _start,
      end: _end,
    );
    _title.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('2) Curriculum Planner')),
      body: FutureBuilder(
        future: Future.wait(
            [PlannerService.listRoadmaps(), PlannerService.listCurriculums()]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final roadmaps = snapshot.data![0];
          final curriculums = snapshot.data![1];

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _roadmapId,
                    items: roadmaps
                        .map<DropdownMenuItem<String>>((g) => DropdownMenuItem(
                            value: g['id'] as String,
                            child: Text(g['title'] ?? '-')))
                        .toList(),
                    onChanged: (v) => setState(() => _roadmapId = v),
                    decoration: const InputDecoration(labelText: '연결할 Roadmap'),
                  ),
                  TextField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: '커리큘럼 제목')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: Text(
                            '시작: ${_start.toIso8601String().substring(0, 10)}')),
                    TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: _start);
                          if (d != null) setState(() => _start = d);
                        },
                        child: const Text('변경')),
                  ]),
                  Row(children: [
                    Expanded(
                        child: Text(
                            '종료: ${_end.toIso8601String().substring(0, 10)}')),
                    TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: _end);
                          if (d != null) setState(() => _end = d);
                        },
                        child: const Text('변경')),
                  ]),
                  ElevatedButton(
                      onPressed: _create, child: const Text('커리큘럼 생성')),
                  const Divider(height: 28),
                  ...curriculums.map((c) => Card(
                          child: ListTile(
                        title: Text(c['title'] ?? '-'),
                        subtitle: Text(
                          '${c['start_date']} ~ ${c['end_date']}\nTodo는 /todos에서 원하는 날짜로 수동 추가',
                        ),
                      ))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
