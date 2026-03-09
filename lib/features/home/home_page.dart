import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/search_service.dart';
import '../../services/planner_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription? _authSub;
  Timer? _tick;
  DateTime? _lastSignedInAt;
  int _searchCount = 0;
  int _guidelineCount = 0;
  int _curriculumCount = 0;
  int _doneTodoCount = 0;

  @override
  void initState() {
    super.initState();
    if (AuthService.currentUser() != null) {
      _lastSignedInAt = DateTime.now();
    }
    _loadKpi();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _loadKpi());

    _authSub = AuthService.authStateChanges().listen((state) {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.signedIn) {
        _lastSignedInAt = DateTime.now();
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
      final count = await SearchService.getSearchItemCount();
      final planner = await PlannerService.dashboardKpi();
      if (!mounted) return;
      setState(() {
        _searchCount = count;
        _guidelineCount = planner['guidelines'] ?? 0;
        _curriculumCount = planner['curriculums'] ?? 0;
        _doneTodoCount = planner['todos_done'] ?? 0;
      });
    } catch (_) {
      // KPI는 실패해도 화면 전체를 깨지 않게 무시
    }
  }

  String _formatLastSignedIn() {
    if (_lastSignedInAt == null) return '-';
    final dt = _lastSignedInAt!;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

    return Scaffold(
      appBar: AppBar(title: const Text('GUICULUM')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Architecture-first Flutter prototype',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: user == null ? Colors.grey : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(user == null ? '로그아웃 상태' : '로그인 상태'),
                ],
              ),
              const SizedBox(height: 8),
              Text('계정: ${user == null ? '-' : (user.email ?? user.id)}'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Login')),
                  ElevatedButton(
                      onPressed: () => context.go('/search'),
                      child: const Text('Search (Rx)')),
                  ElevatedButton(
                      onPressed: () => context.go('/profile'),
                      child: const Text('Profile')),
                  ElevatedButton(
                      onPressed: () => context.go('/guidelines'),
                      child: const Text('Guideline')),
                  ElevatedButton(
                      onPressed: () => context.go('/curriculums'),
                      child: const Text('Curriculum')),
                  ElevatedButton(
                      onPressed: () => context.go('/todos'),
                      child: const Text('Todo')),
                  ElevatedButton(
                      onPressed: () => context.go('/calendar'),
                      child: const Text('Calendar')),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.route),
                  title: const Text('핵심 플로우 진행 현황'),
                  subtitle: Text(
                      'Guideline $_guidelineCount → Curriculum $_curriculumCount → Done Todo $_doneTodoCount'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('내 프로필'),
                  subtitle:
                      Text(user == null ? '로그인 필요' : (user.email ?? user.id)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/profile'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('최근 검색'),
                  subtitle: Text('검색 인덱스 항목 수: $_searchCount'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/search'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('세션 상태'),
                  subtitle: Text(
                    user == null
                        ? '현재 비로그인'
                        : '현재 로그인 세션 활성\n최근 로그인: ${_formatLastSignedIn()}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
