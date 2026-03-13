import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class PlannerService {
  static SupabaseClient get _c => Supabase.instance.client;

  static bool get _useMysqlApi =>
      (dotenv.env['USE_MYSQL_API'] ?? 'false').toLowerCase() == 'true';
  static String get _apiBase =>
      dotenv.env['MYSQL_API_BASE_URL'] ?? 'http://127.0.0.1:8100';

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
    final r = await http.post(Uri.parse('$_apiBase$path'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (r.statusCode >= 400) throw Exception('API 오류: ${r.body}');
  }

  static Future<void> _patch(String path, Map<String, dynamic> body) async {
    final r = await http.patch(Uri.parse('$_apiBase$path'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (r.statusCode >= 400) throw Exception('API 오류: ${r.body}');
  }

  static Future<void> _delete(String path) async {
    final r = await http.delete(Uri.parse('$_apiBase$path'));
    if (r.statusCode >= 400) throw Exception('API 오류: ${r.body}');
  }

  static Future<List<Map<String, dynamic>>> listGuidelines() async {
    if (_useMysqlApi) return _getList('/guidelines?user_id=1');
    return (await _c
            .from('guidelines')
            .select('*')
            .order('created_at', ascending: false))
        .cast<Map<String, dynamic>>();
  }

  static Future<void> createGuideline(
      {required String role, required String title, String notes = ''}) async {
    if (_useMysqlApi) {
      return _post('/guidelines', {
        'user_id': 1,
        'target_role': role,
        'title': title,
        'notes': notes,
      });
    }
    await _c.from('guidelines').insert({
      'user_id': _uid(),
      'target_role': role,
      'title': title,
      'notes': notes
    });
  }

  static Future<List<Map<String, dynamic>>> listCurriculums() async {
    if (_useMysqlApi) return _getList('/curriculums?user_id=1');
    return (await _c
            .from('curriculums')
            .select('*, guidelines(title,target_role)')
            .order('start_date', ascending: true))
        .cast<Map<String, dynamic>>();
  }

  static Future<void> createCurriculum(
      {required String guidelineId,
      required String title,
      required DateTime start,
      required DateTime end}) async {
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

  static Future<void> setTodoStatus(
      {required String todoId, required String status}) async {
    if (_useMysqlApi) {
      return _patch('/todos/${int.tryParse(todoId) ?? 0}', {'status': status});
    }
    await _c.from('todos').update({'status': status}).eq('id', todoId);
  }

  static Future<void> updateTodoTitle(
      {required String todoId, required String title}) async {
    if (_useMysqlApi) {
      return _patch(
          '/todos/${int.tryParse(todoId) ?? 0}', {'title': title.trim()});
    }
    await _c.from('todos').update({'title': title.trim()}).eq('id', todoId);
  }

  static Future<void> updateTodoPriority(
      {required String todoId, required String priority}) async {
    if (_useMysqlApi) {
      return _patch(
          '/todos/${int.tryParse(todoId) ?? 0}', {'priority': priority});
    }
    await _c.from('todos').update({'priority': priority}).eq('id', todoId);
  }

  static Future<void> moveTodosDueDate(
      {required List<String> todoIds, required DateTime dueDate}) async {
    if (todoIds.isEmpty) return;
    if (_useMysqlApi) {
      return _post('/todos/bulk-move', {
        'ids': todoIds
            .map((e) => int.tryParse(e) ?? 0)
            .where((e) => e > 0)
            .toList(),
        'due_date': dueDate.toIso8601String().substring(0, 10),
      });
    }
    await _c.from('todos').update({
      'due_date': dueDate.toIso8601String().substring(0, 10)
    }).inFilter('id', todoIds);
  }

  static Future<void> deleteTodo({required String todoId}) async {
    if (_useMysqlApi) return _delete('/todos/${int.tryParse(todoId) ?? 0}');
    await _c.from('todos').delete().eq('id', todoId);
  }

  static Future<void> updateTodoDueDate(
      {required String todoId, DateTime? dueDate}) async {
    if (_useMysqlApi) {
      return _patch('/todos/${int.tryParse(todoId) ?? 0}', {
        'due_date': dueDate?.toIso8601String().substring(0, 10),
      });
    }
    await _c
        .from('todos')
        .update({'due_date': dueDate?.toIso8601String().substring(0, 10)}).eq(
            'id', todoId);
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

  static Future<void> createWeeklyReview({
    required String weekLabel,
    required String wins,
    required String lows,
    required String nextPlan,
  }) async {
    if (_useMysqlApi) return;
    await _c.from('weekly_reviews').insert({
      'user_id': _uid(),
      'week_label': weekLabel,
      'wins': wins,
      'lows': lows,
      'next_plan': nextPlan,
    });
  }

  static Future<List<Map<String, dynamic>>> listWeeklyReviews() async {
    if (_useMysqlApi) return [];
    return (await _c
            .from('weekly_reviews')
            .select('*')
            .order('created_at', ascending: false)
            .limit(20))
        .cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> computeRiskInsights() async {
    final todos = await listTodos();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final soon = today.add(const Duration(days: 2));

    int overdue = 0;
    int due48 = 0;
    int dueToday = 0;
    int dueTomorrow = 0;
    int inProgress = 0;
    int done = 0;
    int aligned = 0;

    for (final t in todos) {
      final s = (t['status'] ?? 'todo').toString();
      if (s == 'in_progress') inProgress++;
      if (s == 'done') done++;
      final hasCurriculum = (t['curriculum_id'] ?? '').toString().isNotEmpty;
      if (hasCurriculum) aligned++;

      final d = DateTime.tryParse((t['due_date'] ?? '').toString());
      if (d == null) continue;
      final dd = DateTime(d.year, d.month, d.day);
      if (dd.isBefore(today) && s != 'done') overdue++;
      if (!dd.isBefore(today) && !dd.isAfter(soon) && s != 'done') due48++;
      if (dd == today && s != 'done') dueToday++;
      if (dd == tomorrow && s != 'done') dueTomorrow++;
    }

    final doneRate = todos.isEmpty ? 0.0 : done / todos.length;
    final alignmentScore = todos.isEmpty ? 0.0 : aligned / todos.length;
    return {
      'overdue': overdue,
      'due_48h': due48,
      'due_today': dueToday,
      'due_tomorrow': dueTomorrow,
      'in_progress': inProgress,
      'done_rate': doneRate,
      'alignment_score': alignmentScore,
    };
  }

  static Future<Map<String, dynamic>> goalProgress() async {
    final gs = await listGuidelines();
    final cs = await listCurriculums();
    final ts = await listTodos();
    final done = ts.where((e) => (e['status'] ?? 'todo') == 'done').length;
    final rate = ts.isEmpty ? 0.0 : done / ts.length;

    return {
      'guidelines': gs.length,
      'curriculums': cs.length,
      'todos': ts.length,
      'done_todos': done,
      'goal_achievement_rate': rate,
    };
  }

  // ===== Career/Portfolio =====
  static Future<List<Map<String, dynamic>>> listPortfolioChecklist() async {
    if (_useMysqlApi) return [];
    return (await _c
            .from('portfolio_checklists')
            .select('*')
            .order('created_at', ascending: false))
        .cast<Map<String, dynamic>>();
  }

  static Future<void> addPortfolioChecklist(
      {required String category, required String title}) async {
    if (_useMysqlApi) return;
    await _c.from('portfolio_checklists').insert({
      'user_id': _uid(),
      'category': category,
      'title': title,
      'done': false,
    });
  }

  static Future<void> togglePortfolioChecklist(String id, bool done) async {
    if (_useMysqlApi) return;
    await _c.from('portfolio_checklists').update({'done': done}).eq('id', id);
  }

  static Future<List<Map<String, dynamic>>> listInterviewCards() async {
    if (_useMysqlApi) return [];
    return (await _c
            .from('interview_cards')
            .select('*')
            .order('created_at', ascending: false))
        .cast<Map<String, dynamic>>();
  }

  static Future<void> addInterviewCard(
      {required String question,
      String answer = '',
      String feedback = ''}) async {
    if (_useMysqlApi) return;
    await _c.from('interview_cards').insert({
      'user_id': _uid(),
      'question': question,
      'answer': answer,
      'mock_feedback': feedback,
    });
  }

  static Future<List<Map<String, dynamic>>> listResumeVersions() async {
    if (_useMysqlApi) return [];
    return (await _c
            .from('resume_versions')
            .select('*')
            .order('created_at', ascending: false))
        .cast<Map<String, dynamic>>();
  }

  static Future<void> addResumeVersion(
      {required String company,
      required String versionLabel,
      String notes = ''}) async {
    if (_useMysqlApi) return;
    await _c.from('resume_versions').insert({
      'user_id': _uid(),
      'company': company,
      'version_label': versionLabel,
      'notes': notes,
    });
  }

  // ===== Habits / Pomodoro =====
  static Future<List<Map<String, dynamic>>> listHabitLogs() async {
    if (_useMysqlApi) return [];
    return (await _c
            .from('habit_logs')
            .select('*')
            .order('log_date', ascending: false)
            .limit(120))
        .cast<Map<String, dynamic>>();
  }

  static Future<void> logHabit(
      {required String habitName,
      required DateTime date,
      required int minutes}) async {
    if (_useMysqlApi) return;
    await _c.from('habit_logs').upsert({
      'user_id': _uid(),
      'habit_name': habitName,
      'log_date': date.toIso8601String().substring(0, 10),
      'minutes': minutes,
    });
  }

  static Future<int> autoReplanOverdueTodos() async {
    final todos = await listTodos();
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    int moved = 0;
    for (final t in todos) {
      final status = (t['status'] ?? 'todo').toString();
      if (status == 'done') continue;
      final d = DateTime.tryParse((t['due_date'] ?? '').toString());
      if (d == null) continue;
      final dd = DateTime(d.year, d.month, d.day);
      if (dd.isBefore(base)) {
        await updateTodoDueDate(
            todoId: (t['id'] ?? '').toString(),
            dueDate: base.add(const Duration(days: 1)));
        moved++;
      }
    }
    return moved;
  }

  // ===== Gamification =====
  static Future<Map<String, dynamic>> gamificationStats() async {
    final habits = await listHabitLogs();
    final todos = await listTodos();
    int streak = 0;
    final today = DateTime.now();
    DateTime cursor = DateTime(today.year, today.month, today.day);

    final daysDone = <String>{};
    for (final h in habits) {
      final d = (h['log_date'] ?? '').toString();
      if (d.isNotEmpty) daysDone.add(d);
    }

    while (true) {
      final key = cursor.toIso8601String().substring(0, 10);
      if (daysDone.contains(key)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    final done = todos.where((t) => (t['status'] ?? 'todo') == 'done').length;
    final level = (done ~/ 10) + 1;
    final badge =
        streak >= 30 ? '30일 연속 달성' : (streak >= 7 ? '7일 연속 달성' : '시작 배지');

    return {
      'streak': streak,
      'level': level,
      'badge': badge,
      'heatmap_days': daysDone.toList(),
    };
  }

  // ===== Export / Share =====
  static Future<void> exportSnapshotCsvToClipboard() async {
    final guidelines = await listGuidelines();
    final curriculums = await listCurriculums();
    final todos = await listTodos();

    final sb = StringBuffer();
    sb.writeln('section,id,title,status_or_notes,due_or_date');
    for (final g in guidelines) {
      sb.writeln(
          'guideline,${g['id']},"${(g['title'] ?? '').toString().replaceAll('"', '""')}","${(g['notes'] ?? '').toString().replaceAll('"', '""')}",');
    }
    for (final c in curriculums) {
      sb.writeln(
          'curriculum,${c['id']},"${(c['title'] ?? '').toString().replaceAll('"', '""')}",,${c['start_date']}~${c['end_date']}');
    }
    for (final t in todos) {
      sb.writeln(
          'todo,${t['id']},"${(t['title'] ?? '').toString().replaceAll('"', '""')}",${t['status']},${t['due_date'] ?? ''}');
    }

    await Clipboard.setData(ClipboardData(text: sb.toString()));
  }

  static Future<String> mentorSharePath() async {
    final kpi = await dashboardKpi();
    return '/share?g=${kpi['guidelines']}&c=${kpi['curriculums']}&d=${kpi['todos_done']}';
  }

  static Future<String> aiSuggestNextStep() async {
    final insights = await computeRiskInsights();
    if ((insights['overdue'] as int? ?? 0) > 0) {
      return '지연 Todo가 있습니다. 오늘은 지연 항목 재배치부터 하세요.';
    }
    if ((insights['due_48h'] as int? ?? 0) > 0) {
      return '48시간 내 마감 항목을 우선 처리하세요.';
    }
    return '이번 주 대목표 기준으로 소목표 3개를 캘린더에 배치하세요.';
  }
}
