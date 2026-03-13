import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/planner_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription? _authSub;
  Timer? _tick;
  int _guidelineCount = 0;
  int _curriculumCount = 0;
  int _doneTodoCount = 0;
  int _todayTodoCount = 0;
  int _todayInProgressCount = 0;
  int _todayDoneCount = 0;
  int _daysRemaining = 0;
  String _nextCurriculumTitle = '-';
  String _nextCurriculumRange = '-';

  @override
  void initState() {
    super.initState();
    _loadKpi();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _loadKpi());

    _authSub = AuthService.authStateChanges().listen((state) {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.signedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 성공! 프로필 동기화 중...')),
        );
      } else if (state.event == AuthChangeEvent.signedOut) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃 되었습니다.')),
        );
      }
      _loadKpi();
      setState(() {});
    });
  }

  Future<void> _loadKpi() async {
    try {
      final planner = await PlannerService.dashboardKpi();
      final curriculums = await PlannerService.listCurriculums();
      final todos = await PlannerService.listTodos();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayTodoRows = todos.where((t) {
        final d = DateTime.tryParse((t['due_date'] ?? '').toString());
        return d != null &&
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
      }).toList();
      final todayTodos = todayTodoRows.length;
      final todayInProgress = todayTodoRows
          .where((t) => (t['status'] ?? 'todo').toString() == 'in_progress')
          .length;
      final todayDone = todayTodoRows
          .where((t) => (t['status'] ?? 'todo').toString() == 'done')
          .length;

      String nextTitle = '-';
      String nextRange = '-';
      int daysRemaining = 0;
      if (curriculums.isNotEmpty) {
        final sorted = [...curriculums]..sort((a, b) => (a['end_date'] ?? '')
            .toString()
            .compareTo((b['end_date'] ?? '').toString()));
        final c = sorted.first;
        nextTitle = (c['title'] ?? '-').toString();
        final s = (c['start_date'] ?? '-').toString();
        final e = (c['end_date'] ?? '-').toString();
        nextRange = '$s ~ $e';
        final end = DateTime.tryParse(e);
        if (end != null) {
          daysRemaining = end.difference(today).inDays;
          if (daysRemaining < 0) daysRemaining = 0;
        }
      }

      if (!mounted) return;
      setState(() {
        _guidelineCount = planner['guidelines'] ?? 0;
        _curriculumCount = planner['curriculums'] ?? 0;
        _doneTodoCount = planner['todos_done'] ?? 0;
        _todayTodoCount = todayTodos;
        _todayInProgressCount = todayInProgress;
        _todayDoneCount = todayDone;
        _daysRemaining = daysRemaining;
        _nextCurriculumTitle = nextTitle;
        _nextCurriculumRange = nextRange;
      });
    } catch (_) {
      // KPI는 실패해도 화면 전체를 깨지 않게 무시
    }
  }

  Widget _statCard(String title, String value, String sub) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(sub),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(user == null ? '로그아웃 상태' : '로그인: ${user.email ?? user.id}'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard('Goal Progress', '$_doneTodoCount done',
                  '$_todayTodoCount due today'),
              _statCard('Milestones', '$_curriculumCount curriculums',
                  '$_guidelineCount guidelines'),
              _statCard('Days Remaining', '$_daysRemaining days',
                  _nextCurriculumTitle),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Curriculum Timeline',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.timeline),
                          title: Text(_nextCurriculumTitle),
                          subtitle: Text(_nextCurriculumRange),
                          trailing: TextButton(
                              onPressed: () => context.go('/curriculums'),
                              child: const Text('열기')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Today's Tasks",
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.today),
                          title: Text('오늘 마감 Todo: $_todayTodoCount개'),
                          subtitle: Text(
                            '진행중: $_todayInProgressCount · 완료: $_todayDoneCount · 완료율: ${_todayTodoCount == 0 ? 0 : ((_todayDoneCount / _todayTodoCount) * 100).toStringAsFixed(0)}%',
                          ),
                          trailing: TextButton(
                              onPressed: () => context.go('/calendar'),
                              child: const Text('캘린더')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
