import 'package:flutter/material.dart';

import '../../services/planner_service.dart';

class GuidelinePage extends StatefulWidget {
  const GuidelinePage({super.key});

  @override
  State<GuidelinePage> createState() => _GuidelinePageState();
}

class _GuidelinePageState extends State<GuidelinePage> {
  final _role = TextEditingController(text: 'Flutter Developer');
  final _title = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _role.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    await PlannerService.createGuideline(
        role: _role.text.trim(),
        title: _title.text.trim(),
        notes: _notes.text.trim());
    _title.clear();
    _notes.clear();
    if (mounted) setState(() {});
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
                  TextField(
                      controller: _role,
                      decoration: const InputDecoration(labelText: '목표 직무')),
                  TextField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: '가이드라인 제목')),
                  TextField(
                      controller: _notes,
                      decoration: const InputDecoration(labelText: '학습 원칙/메모')),
                  const SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: _create, child: const Text('가이드라인 생성')),
                  const Divider(height: 28),
                  ...items.map((e) => Card(
                      child: ListTile(
                          title: Text(e['title'] ?? '-'),
                          subtitle: Text('${e['target_role'] ?? '-'}')))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
