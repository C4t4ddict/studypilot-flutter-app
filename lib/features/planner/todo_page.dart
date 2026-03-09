import 'package:flutter/material.dart';

import '../../services/planner_service.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  String? _curriculumId;
  final _title = TextEditingController();
  DateTime? _dueDate;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_curriculumId == null || _title.text.trim().isEmpty) return;
    await PlannerService.createTodo(
      curriculumId: _curriculumId!,
      title: _title.text.trim(),
      dueDate: _dueDate,
    );
    _title.clear();
    _dueDate = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3) Todo Execution')),
      body: FutureBuilder(
        future: Future.wait(
            [PlannerService.listCurriculums(), PlannerService.listTodos()]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final curriculums = snapshot.data![0];
          final todos = snapshot.data![1];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _curriculumId,
                items: curriculums
                    .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(c['title'] ?? '-')))
                    .toList(),
                onChanged: (v) => setState(() => _curriculumId = v),
                decoration: const InputDecoration(labelText: '연결할 Curriculum'),
              ),
              TextField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Todo 제목')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '마감일: ${_dueDate == null ? '미지정' : _dueDate!.toIso8601String().substring(0, 10)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: _dueDate ?? DateTime.now(),
                      );
                      if (d != null) setState(() => _dueDate = d);
                    },
                    child: const Text('날짜 선택'),
                  ),
                ],
              ),
              ElevatedButton(onPressed: _create, child: const Text('Todo 추가')),
              const Divider(height: 28),
              ...todos.map((t) {
                final done = (t['status'] ?? 'todo') == 'done';
                return Card(
                  child: CheckboxListTile(
                    value: done,
                    title: Text(t['title'] ?? '-'),
                    subtitle: Text('마감: ${t['due_date'] ?? '-'}'),
                    onChanged: (v) async {
                      await PlannerService.setTodoStatus(
                        todoId: t['id'] as String,
                        status: (v ?? false) ? 'done' : 'todo',
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
