import 'package:supabase_flutter/supabase_flutter.dart';

class PlannerService {
  static SupabaseClient get _c => Supabase.instance.client;

  static String _uid() {
    final u = _c.auth.currentUser;
    if (u == null) throw Exception('로그인이 필요합니다.');
    return u.id;
  }

  static Future<List<Map<String, dynamic>>> listGuidelines() async {
    return (await _c
            .from('guidelines')
            .select('*')
            .order('created_at', ascending: false))
        .cast<Map<String, dynamic>>();
  }

  static Future<void> createGuideline(
      {required String role, required String title, String notes = ''}) async {
    await _c.from('guidelines').insert({
      'user_id': _uid(),
      'target_role': role,
      'title': title,
      'notes': notes,
    });
  }

  static Future<List<Map<String, dynamic>>> listCurriculums() async {
    return (await _c
            .from('curriculums')
            .select('*, guidelines(title,target_role)')
            .order('start_date', ascending: true))
        .cast<Map<String, dynamic>>();
  }

  static Future<void> createCurriculum({
    required String guidelineId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    await _c.from('curriculums').insert({
      'user_id': _uid(),
      'guideline_id': guidelineId,
      'title': title,
      'start_date': start.toIso8601String().substring(0, 10),
      'end_date': end.toIso8601String().substring(0, 10),
    });
  }

  static Future<List<Map<String, dynamic>>> listTodos() async {
    return (await _c
            .from('todos')
            .select('*, curriculums(title)')
            .order('due_date', ascending: true))
        .cast<Map<String, dynamic>>();
  }

  static Future<void> createTodo(
      {required String curriculumId,
      required String title,
      DateTime? dueDate,
      String priority = 'medium'}) async {
    await _c.from('todos').insert({
      'user_id': _uid(),
      'curriculum_id': curriculumId,
      'title': title,
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'status': 'todo',
      'priority': priority,
    });
  }

  static Future<void> setTodoStatus(
      {required String todoId, required String status}) async {
    await _c.from('todos').update({'status': status}).eq('id', todoId);
  }

  static Future<void> updateTodoTitle(
      {required String todoId, required String title}) async {
    await _c.from('todos').update({'title': title.trim()}).eq('id', todoId);
  }

  static Future<void> updateTodoPriority(
      {required String todoId, required String priority}) async {
    await _c.from('todos').update({'priority': priority}).eq('id', todoId);
  }

  static Future<void> moveTodosDueDate(
      {required List<String> todoIds, required DateTime dueDate}) async {
    if (todoIds.isEmpty) return;
    await _c.from('todos').update({
      'due_date': dueDate.toIso8601String().substring(0, 10),
    }).inFilter('id', todoIds);
  }

  static Future<void> deleteTodo({required String todoId}) async {
    await _c.from('todos').delete().eq('id', todoId);
  }

  static Future<void> updateTodoDueDate(
      {required String todoId, DateTime? dueDate}) async {
    await _c.from('todos').update({
      'due_date': dueDate?.toIso8601String().substring(0, 10),
    }).eq('id', todoId);
  }

  static Future<Map<String, int>> dashboardKpi() async {
    final gs =
        await _c.from('guidelines').select('id').count(CountOption.exact);
    final cs =
        await _c.from('curriculums').select('id').count(CountOption.exact);
    final ts = await _c.from('todos').select('id,status');
    final done = (ts as List)
        .where((e) => (e as Map<String, dynamic>)['status'] == 'done')
        .length;
    return {
      'guidelines': gs.count,
      'curriculums': cs.count,
      'todos_done': done
    };
  }

  static Future<Map<String, dynamic>> flowSummary() async {
    final guidelines = await listGuidelines();
    final curriculums = await listCurriculums();
    final todos = await listTodos();

    final linkedGuidelineIds = curriculums
        .map((c) => c['guideline_id'] as String?)
        .whereType<String>()
        .toSet();
    final linkedCurriculumIds = todos
        .map((t) => t['curriculum_id'] as String?)
        .whereType<String>()
        .toSet();
    final doneTodos = todos.where((t) => (t['status'] ?? 'todo') == 'done').length;

    return {
      'guidelineCount': guidelines.length,
      'curriculumCount': curriculums.length,
      'todoCount': todos.length,
      'doneTodoCount': doneTodos,
      'guidelinesWithCurriculum': linkedGuidelineIds.length,
      'curriculumsWithTodo': linkedCurriculumIds.length,
    };
  }

  static Future<Map<String, dynamic>> dashboardAnalytics() async {
    final curriculums = await listCurriculums();
    final todos = await listTodos();
    final now = DateTime.now();
    final todayKey = now.toIso8601String().substring(0, 10);
    final weekKeys = List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day - (6 - i));
      return d.toIso8601String().substring(0, 10);
    });

    final done = todos.where((t) => (t['status'] ?? 'todo') == 'done').length;
    final inProgress = todos.where((t) => (t['status'] ?? 'todo') == 'in_progress').length;
    final pending = todos.where((t) => (t['status'] ?? 'todo') == 'todo').length;
    final todayTodos = todos.where((t) => t['due_date'] == todayKey).length;
    final todayDone = todos.where((t) => t['due_date'] == todayKey && (t['status'] ?? 'todo') == 'done').length;
    final weekActivity = weekKeys
        .map((key) => {
              'date': key,
              'count': todos.where((t) => t['due_date'] == key).length,
            })
        .toList();

    final curriculumProgress = curriculums.map((c) {
      final items = todos.where((t) => t['curriculum_id'] == c['id']).toList();
      final itemsDone = items.where((t) => (t['status'] ?? 'todo') == 'done').length;
      return {
        'title': c['title'] ?? '-',
        'total': items.length,
        'done': itemsDone,
        'progress': items.isEmpty ? 0.0 : itemsDone / items.length,
      };
    }).toList();

    return {
      'todoTotal': todos.length,
      'todoDone': done,
      'todoInProgress': inProgress,
      'todoPending': pending,
      'todayTotal': todayTodos,
      'todayDone': todayDone,
      'weekActivity': weekActivity,
      'curriculumProgress': curriculumProgress,
    };
  }
}
