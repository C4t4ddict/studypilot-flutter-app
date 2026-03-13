import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class PlannerService {
  static SupabaseClient get _c => Supabase.instance.client;

  static bool get _useMysqlApi => (dotenv.env['USE_MYSQL_API'] ?? 'false').toLowerCase() == 'true';
  static String get _apiBase => dotenv.env['MYSQL_API_BASE_URL'] ?? 'http://127.0.0.1:8100';

  static String _uid() {
    final u = _c.auth.currentUser;
    if (u == null) throw Exception('로그인이 필요합니다.');
    return u.id;
  }

  static Future<List<Map<String, dynamic>>> _getList(String path) async {
    final r = await http.get(Uri.parse('$_apiBase$path'));
    if (r.statusCode >= 400) throw Exception('API 오류: ${r.body}');
    final v = jsonDecode(r.body) as List;
    return v.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> _getObj(String path) async {
    final r = await http.get(Uri.parse('$_apiBase$path'));
    if (r.statusCode >= 400) throw Exception('API 오류: ${r.body}');
    return (jsonDecode(r.body) as Map).cast<String, dynamic>();
  }

  static Future<void> _post(String path, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$_apiBase$path'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (r.statusCode >= 400) throw Exception('API 오류: ${r.body}');
  }

  static Future<void> _patch(String path, Map<String, dynamic> body) async {
    final r = await http.patch(Uri.parse('$_apiBase$path'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (r.statusCode >= 400) throw Exception('API 오류: ${r.body}');
  }

  static Future<void> _delete(String path) async {
    final r = await http.delete(Uri.parse('$_apiBase$path'));
    if (r.statusCode >= 400) throw Exception('API 오류: ${r.body}');
  }

  static Future<List<Map<String, dynamic>>> listGuidelines() async {
    if (_useMysqlApi) return _getList('/guidelines?user_id=1');
    return (await _c.from('guidelines').select('*').order('created_at', ascending: false)).cast<Map<String, dynamic>>();
  }

  static Future<void> createGuideline({required String role, required String title, String notes = ''}) async {
    if (_useMysqlApi) return _post('/guidelines', {'user_id': 1, 'target_role': role, 'title': title, 'notes': notes});
    await _c.from('guidelines').insert({'user_id': _uid(), 'target_role': role, 'title': title, 'notes': notes});
  }

  static Future<List<Map<String, dynamic>>> listCurriculums() async {
    if (_useMysqlApi) return _getList('/curriculums?user_id=1');
    return (await _c.from('curriculums').select('*, guidelines(title,target_role)').order('start_date', ascending: true)).cast<Map<String, dynamic>>();
  }

  static Future<void> createCurriculum({required String guidelineId, required String title, required DateTime start, required DateTime end}) async {
    if (_useMysqlApi) {
      return _post('/curriculums', {
        'user_id': 1,
        'guideline_id': int.tryParse(guidelineId) ?? 1,
        'title': title,
        'start_date': start.toIso8601String().substring(0, 10),
        'end_date': end.toIso8601String().substring(0, 10),
      });
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
    if (_useMysqlApi) return _getList('/todos?user_id=1');
    return (await _c.from('todos').select('*, curriculums(title)').order('due_date', ascending: true)).cast<Map<String, dynamic>>();
  }

  static Future<void> createTodo({required String curriculumId, required String title, DateTime? dueDate, String priority = 'medium'}) async {
    if (_useMysqlApi) {
      return _post('/todos', {
        'user_id': 1,
        'curriculum_id': int.tryParse(curriculumId) ?? 1,
        'title': title,
        'due_date': dueDate?.toIso8601String().substring(0, 10),
        'status': 'todo',
        'priority': priority,
      });
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
    if (_useMysqlApi) return _patch('/todos/${int.tryParse(todoId) ?? 0}', {'status': status});
    await _c.from('todos').update({'status': status}).eq('id', todoId);
  }

  static Future<void> updateTodoTitle({required String todoId, required String title}) async {
    if (_useMysqlApi) return _patch('/todos/${int.tryParse(todoId) ?? 0}', {'title': title.trim()});
    await _c.from('todos').update({'title': title.trim()}).eq('id', todoId);
  }

  static Future<void> updateTodoPriority({required String todoId, required String priority}) async {
    if (_useMysqlApi) return _patch('/todos/${int.tryParse(todoId) ?? 0}', {'priority': priority});
    await _c.from('todos').update({'priority': priority}).eq('id', todoId);
  }

  static Future<void> moveTodosDueDate({required List<String> todoIds, required DateTime dueDate}) async {
    if (todoIds.isEmpty) return;
    if (_useMysqlApi) {
      return _post('/todos/bulk-move', {
        'ids': todoIds.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList(),
        'due_date': dueDate.toIso8601String().substring(0, 10),
      });
    }
    await _c.from('todos').update({'due_date': dueDate.toIso8601String().substring(0, 10)}).inFilter('id', todoIds);
  }

  static Future<void> deleteTodo({required String todoId}) async {
    if (_useMysqlApi) return _delete('/todos/${int.tryParse(todoId) ?? 0}');
    await _c.from('todos').delete().eq('id', todoId);
  }

  static Future<void> updateTodoDueDate({required String todoId, DateTime? dueDate}) async {
    if (_useMysqlApi) {
      return _patch('/todos/${int.tryParse(todoId) ?? 0}', {
        'due_date': dueDate?.toIso8601String().substring(0, 10),
      });
    }
    await _c.from('todos').update({'due_date': dueDate?.toIso8601String().substring(0, 10)}).eq('id', todoId);
  }

  static Future<Map<String, int>> dashboardKpi() async {
    if (_useMysqlApi) {
      final m = await _getObj('/dashboard/kpi?user_id=1');
      return {
        'guidelines': (m['guidelines'] ?? 0) as int,
        'curriculums': (m['curriculums'] ?? 0) as int,
        'todos_done': (m['todos_done'] ?? 0) as int,
      };
    }
    final gs = await _c.from('guidelines').select('id').count(CountOption.exact);
    final cs = await _c.from('curriculums').select('id').count(CountOption.exact);
    final ts = await _c.from('todos').select('id,status');
    final done = (ts as List).where((e) => (e as Map<String, dynamic>)['status'] == 'done').length;
    return {'guidelines': gs.count, 'curriculums': cs.count, 'todos_done': done};
  }
}
