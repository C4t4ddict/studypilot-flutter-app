import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

class PlannerService {
  static SupabaseClient get _c => Supabase.instance.client;
  static const _guidelineKey = 'demo_guidelines';
  static const _curriculumKey = 'demo_curriculums';
  static const _todoKey = 'demo_todos';

  static String _uid() {
    final u = _c.auth.currentUser;
    if (u == null) throw Exception('로그인이 필요합니다.');
    return u.id;
  }

  static String _demoId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  static Future<List<Map<String, dynamic>>> _getDemoList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key) ?? const [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> _setDemoList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value.map(jsonEncode).toList());
  }

  static Future<List<Map<String, dynamic>>> listGuidelines() async {
    if (AuthService.isDemoMode) {
      return _getDemoList(_guidelineKey);
    }
    return (await _c.from('guidelines').select('*').order('created_at', ascending: false)).cast<Map<String, dynamic>>();
  }

  static Future<void> createGuideline({required String role, required String title, String notes = ''}) async {
    if (AuthService.isDemoMode) {
      final current = await _getDemoList(_guidelineKey);
      current.insert(0, {
        'id': _demoId('guideline'),
        'target_role': role,
        'title': title,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _setDemoList(_guidelineKey, current);
      return;
    }
    await _c.from('guidelines').insert({'user_id': _uid(), 'target_role': role, 'title': title, 'notes': notes});
  }

  static Future<List<Map<String, dynamic>>> listCurriculums() async {
    if (AuthService.isDemoMode) {
      return _getDemoList(_curriculumKey);
    }
    return (await _c.from('curriculums').select('*, guidelines(title,target_role)').order('start_date', ascending: true)).cast<Map<String, dynamic>>();
  }

  static Future<void> createCurriculum({required String guidelineId, required String title, required DateTime start, required DateTime end}) async {
    if (AuthService.isDemoMode) {
      final current = await _getDemoList(_curriculumKey);
      current.add({
        'id': _demoId('curriculum'),
        'guideline_id': guidelineId,
        'title': title,
        'start_date': start.toIso8601String().substring(0, 10),
        'end_date': end.toIso8601String().substring(0, 10),
      });
      await _setDemoList(_curriculumKey, current);
      return;
    }
    await _c.from('curriculums').insert({
      'user_id': _uid(),
      'guideline_id': guidelineId,
      'title': title,
      'start_date': start.toIso8601String().substring(0, 10),
      'end_date': end.toIso8601String().substring(0, 10),
    });
  }

  static Future<List<Map<String, dynamic>>> listTodos() async {
    if (AuthService.isDemoMode) {
      return _getDemoList(_todoKey);
    }
    return (await _c.from('todos').select('*, curriculums(title)').order('due_date', ascending: true)).cast<Map<String, dynamic>>();
  }

  static Future<void> createTodo({required String curriculumId, required String title, DateTime? dueDate, String priority = 'medium'}) async {
    if (AuthService.isDemoMode) {
      final current = await _getDemoList(_todoKey);
      current.add({
        'id': _demoId('todo'),
        'curriculum_id': curriculumId,
        'title': title,
        'due_date': dueDate?.toIso8601String().substring(0, 10),
        'status': 'todo',
        'priority': priority,
      });
      await _setDemoList(_todoKey, current);
      return;
    }
    await _c.from('todos').insert({
      'user_id': _uid(),
      'curriculum_id': curriculumId,
      'title': title,
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'status': 'todo',
      'priority': priority,
    });
  }

  static Future<void> setTodoStatus({required String todoId, required String status}) async {
    if (AuthService.isDemoMode) {
      final current = await _getDemoList(_todoKey);
      for (final item in current) {
        if (item['id'] == todoId) item['status'] = status;
      }
      await _setDemoList(_todoKey, current);
      return;
    }
    await _c.from('todos').update({'status': status}).eq('id', todoId);
  }

  static Future<void> updateTodoTitle({required String todoId, required String title}) async {
    if (AuthService.isDemoMode) {
      final current = await _getDemoList(_todoKey);
      for (final item in current) {
        if (item['id'] == todoId) item['title'] = title.trim();
      }
      await _setDemoList(_todoKey, current);
      return;
    }
    await _c.from('todos').update({'title': title.trim()}).eq('id', todoId);
  }

  static Future<void> updateTodoPriority({required String todoId, required String priority}) async {
    if (AuthService.isDemoMode) {
      final current = await _getDemoList(_todoKey);
      for (final item in current) {
        if (item['id'] == todoId) item['priority'] = priority;
      }
      await _setDemoList(_todoKey, current);
      return;
    }
    await _c.from('todos').update({'priority': priority}).eq('id', todoId);
  }

  static Future<void> moveTodosDueDate({required List<String> todoIds, required DateTime dueDate}) async {
    if (todoIds.isEmpty) return;
    if (AuthService.isDemoMode) {
      final current = await _getDemoList(_todoKey);
      for (final item in current) {
        if (todoIds.contains(item['id'])) item['due_date'] = dueDate.toIso8601String().substring(0, 10);
      }
      await _setDemoList(_todoKey, current);
      return;
    }
    await _c.from('todos').update({'due_date': dueDate.toIso8601String().substring(0, 10)}).inFilter('id', todoIds);
  }

  static Future<void> deleteTodo({required String todoId}) async {
    if (AuthService.isDemoMode) {
      final current = await _getDemoList(_todoKey);
      current.removeWhere((item) => item['id'] == todoId);
      await _setDemoList(_todoKey, current);
      return;
    }
    await _c.from('todos').delete().eq('id', todoId);
  }

  static Future<void> updateTodoDueDate({required String todoId, DateTime? dueDate}) async {
    if (AuthService.isDemoMode) {
      final current = await _getDemoList(_todoKey);
      for (final item in current) {
        if (item['id'] == todoId) item['due_date'] = dueDate?.toIso8601String().substring(0, 10);
      }
      await _setDemoList(_todoKey, current);
      return;
    }
    await _c.from('todos').update({'due_date': dueDate?.toIso8601String().substring(0, 10)}).eq('id', todoId);
  }

  static Future<Map<String, int>> dashboardKpi() async {
    final gs = await listGuidelines();
    final cs = await listCurriculums();
    final ts = await listTodos();
    final done = ts.where((e) => (e['status'] ?? 'todo') == 'done').length;
    return {'guidelines': gs.length, 'curriculums': cs.length, 'todos_done': done};
  }

  static Future<Map<String, dynamic>> flowSummary() async {
    final guidelines = await listGuidelines();
    final curriculums = await listCurriculums();
    final todos = await listTodos();
    final linkedGuidelineIds = curriculums.map((c) => c['guideline_id'] as String?).whereType<String>().toSet();
    final linkedCurriculumIds = todos.map((t) => t['curriculum_id'] as String?).whereType<String>().toSet();
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
    final weekActivity = weekKeys.map((key) => {'date': key, 'count': todos.where((t) => t['due_date'] == key).length}).toList();
    final curriculumProgress = curriculums.map((c) {
      final items = todos.where((t) => t['curriculum_id'] == c['id']).toList();
      final itemsDone = items.where((t) => (t['status'] ?? 'todo') == 'done').length;
      return {'title': c['title'] ?? '-', 'total': items.length, 'done': itemsDone, 'progress': items.isEmpty ? 0.0 : itemsDone / items.length};
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
