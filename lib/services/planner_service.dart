import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

class PlannerService {
  static SupabaseClient get _c => Supabase.instance.client;
  static const _guidelineKey = 'demo_guidelines';
  static const _curriculumKey = 'demo_curriculums';
  static const _todoKey = 'demo_todos';
  static const segmentPalette = [
    '0xFF0050CB',
    '0xFF006689',
    '0xFF6FCEFE',
    '0xFF445A7F',
    '0xFF7B61FF',
    '0xFF2E8B57',
  ];

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

  static List<Map<String, dynamic>> normalizeSegments(dynamic rawSegments) {
    if (rawSegments is! List) return const [];
    return rawSegments
        .whereType<Map>()
        .map((segment) => Map<String, dynamic>.from(segment))
        .map((segment) => {
              'id': segment['id']?.toString(),
              'name': segment['name']?.toString() ?? '',
              'end_date': segment['end_date']?.toString() ?? '',
              'order': (segment['order'] as num?)?.toInt() ?? 0,
              'color': segment['color']?.toString() ?? segmentPalette.first,
            })
        .where((segment) => segment['name'].toString().trim().isNotEmpty && segment['end_date'].toString().isNotEmpty)
        .toList()
      ..sort((a, b) => ((a['order'] as int?) ?? 0).compareTo((b['order'] as int?) ?? 0));
  }

  static List<Map<String, dynamic>> buildCurriculumSegments(Map<String, dynamic> curriculum) {
    final startDate = DateTime.tryParse((curriculum['start_date'] ?? '').toString());
    final endDate = DateTime.tryParse((curriculum['end_date'] ?? '').toString());
    if (startDate == null || endDate == null) return const [];

    final normalized = normalizeSegments(curriculum['segments']);
    if (normalized.isEmpty) {
      return [
        {
          'id': '${curriculum['id']}-segment-default',
          'name': curriculum['title'] ?? '기본 구간',
          'start_date': startDate.toIso8601String().substring(0, 10),
          'end_date': endDate.toIso8601String().substring(0, 10),
          'order': 0,
          'color': segmentPalette.first,
        },
      ];
    }

    final built = <Map<String, dynamic>>[];
    var currentStart = startDate;
    for (final segment in normalized) {
      final segmentEnd = DateTime.tryParse(segment['end_date']?.toString() ?? '');
      if (segmentEnd == null) continue;
      built.add({
        'id': segment['id'] ?? _demoId('segment'),
        'name': segment['name'],
        'start_date': currentStart.toIso8601String().substring(0, 10),
        'end_date': segmentEnd.toIso8601String().substring(0, 10),
        'order': segment['order'],
        'color': segment['color'] ?? segmentPalette[built.length % segmentPalette.length],
      });
      currentStart = segmentEnd.add(const Duration(days: 1));
    }

    if (currentStart.isBefore(endDate) || currentStart.isAtSameMomentAs(endDate)) {
      built.add({
        'id': '${curriculum['id']}-segment-final',
        'name': normalized.isEmpty ? (curriculum['title'] ?? '마무리') : '최종 정리',
        'start_date': currentStart.toIso8601String().substring(0, 10),
        'end_date': endDate.toIso8601String().substring(0, 10),
        'order': built.length,
        'color': segmentPalette[built.length % segmentPalette.length],
      });
    }

    return built;
  }

  static Map<String, dynamic>? findSegmentForDate(Map<String, dynamic> curriculum, DateTime day) {
    for (final segment in buildCurriculumSegments(curriculum)) {
      final start = DateTime.tryParse((segment['start_date'] ?? '').toString());
      final end = DateTime.tryParse((segment['end_date'] ?? '').toString());
      if (start == null || end == null) continue;
      final current = DateTime(day.year, day.month, day.day);
      if (!current.isBefore(DateTime(start.year, start.month, start.day)) && !current.isAfter(DateTime(end.year, end.month, end.day))) {
        return segment;
      }
    }
    return null;
  }

  static Future<void> _ensureDemoSampleData() async {
    const guidelineId = 'demo-guideline-study-pilot';
    const curriculumId = 'demo-curriculum-study-pilot';

    final guidelines = await _getDemoList(_guidelineKey);
    final curriculums = await _getDemoList(_curriculumKey);
    final todos = await _getDemoList(_todoKey);

    if (!guidelines.any((item) => item['id'] == guidelineId)) {
      guidelines.insert(0, {
        'id': guidelineId,
        'target_role': 'Flutter 프론트엔드 개발자',
        'title': 'Study Pilot 앱 완성 루트',
        'notes': '기초 구조부터 캘린더/투두/배포까지 단계적으로 완성하는 예시 플랜',
        'created_at': DateTime(2026, 7, 1).toIso8601String(),
      });
      await _setDemoList(_guidelineKey, guidelines);
    }

    if (!curriculums.any((item) => item['id'] == curriculumId)) {
      curriculums.insert(0, {
        'id': curriculumId,
        'guideline_id': guidelineId,
        'title': 'Study Pilot 제품 완성 커리큘럼',
        'start_date': '2026-07-01',
        'end_date': '2026-07-31',
        'segments': [
          {'id': 'segment-1', 'name': '기획 정리', 'end_date': '2026-07-07', 'order': 0, 'color': segmentPalette[0]},
          {'id': 'segment-2', 'name': '학습 탭 구현', 'end_date': '2026-07-14', 'order': 1, 'color': segmentPalette[1]},
          {'id': 'segment-3', 'name': '캘린더 연결', 'end_date': '2026-07-21', 'order': 2, 'color': segmentPalette[2]},
          {'id': 'segment-4', 'name': '투두 실행 흐름', 'end_date': '2026-07-26', 'order': 3, 'color': segmentPalette[3]},
        ],
      });
      await _setDemoList(_curriculumKey, curriculums);
    }

    if (!todos.any((item) => (item['curriculum_id'] ?? '') == curriculumId)) {
      todos.addAll([
        {'id': 'todo-1', 'curriculum_id': curriculumId, 'title': '홈 시안 구조 점검', 'due_date': '2026-07-03', 'status': 'done', 'priority': 'high'},
        {'id': 'todo-2', 'curriculum_id': curriculumId, 'title': '학습 탭 연결 상태 확인', 'due_date': '2026-07-10', 'status': 'in_progress', 'priority': 'high'},
        {'id': 'todo-3', 'curriculum_id': curriculumId, 'title': '커리큘럼 분기점 데이터 입력', 'due_date': '2026-07-15', 'status': 'todo', 'priority': 'medium'},
        {'id': 'todo-4', 'curriculum_id': curriculumId, 'title': '학습 캘린더 구간 색상 검수', 'due_date': '2026-07-18', 'status': 'todo', 'priority': 'high'},
        {'id': 'todo-5', 'curriculum_id': curriculumId, 'title': '날짜 팝업에서 오늘 할일 확인', 'due_date': '2026-07-18', 'status': 'todo', 'priority': 'medium'},
        {'id': 'todo-6', 'curriculum_id': curriculumId, 'title': '배포 전 최종 점검', 'due_date': '2026-07-29', 'status': 'todo', 'priority': 'high'},
      ]);
      await _setDemoList(_todoKey, todos);
    }
  }

  static Future<List<Map<String, dynamic>>> listGuidelines() async {
    if (AuthService.isDemoMode) {
      await _ensureDemoSampleData();
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
      await _ensureDemoSampleData();
      return _getDemoList(_curriculumKey);
    }
    return (await _c.from('curriculums').select('*, guidelines(title,target_role), segments').order('start_date', ascending: true)).cast<Map<String, dynamic>>();
  }

  static Future<void> createCurriculum({required String guidelineId, required String title, required DateTime start, required DateTime end, List<Map<String, dynamic>> segments = const []}) async {
    final normalizedSegments = normalizeSegments(segments);
    if (AuthService.isDemoMode) {
      final current = await _getDemoList(_curriculumKey);
      current.add({
        'id': _demoId('curriculum'),
        'guideline_id': guidelineId,
        'title': title,
        'start_date': start.toIso8601String().substring(0, 10),
        'end_date': end.toIso8601String().substring(0, 10),
        'segments': normalizedSegments,
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
      'segments': normalizedSegments,
    });
  }

  static Future<List<Map<String, dynamic>>> listTodos() async {
    if (AuthService.isDemoMode) {
      await _ensureDemoSampleData();
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
