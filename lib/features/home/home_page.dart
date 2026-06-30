import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/planner_service.dart';
import '../../services/search_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription? _authSub;
  Timer? _tick;
  int _searchCount = 0;
  int _guidelineCount = 0;
  int _curriculumCount = 0;
  int _doneTodoCount = 0;
  int _todoInProgressCount = 0;
  int _todoPendingCount = 0;
  int _todayTodoCount = 0;
  int _todayDoneCount = 0;
  int _todayPendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadKpi();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _loadKpi());

    _authSub = AuthService.authStateChanges().listen((state) {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.signedIn) {
      }
      _loadKpi();
      setState(() {});
    });
  }

  Future<void> _loadKpi() async {
    try {
      final count = await SearchService.getSearchItemCount();
      final planner = await PlannerService.dashboardKpi();
      final analytics = await PlannerService.dashboardAnalytics();
      if (!mounted) return;
      setState(() {
        _searchCount = planner['search_count'] ?? count;
        _guidelineCount = planner['guidelines'] ?? 0;
        _curriculumCount = planner['curriculums'] ?? 0;
        _doneTodoCount = planner['todos_done'] ?? 0;
        _todoInProgressCount = analytics['todoInProgress'] ?? 0;
        _todoPendingCount = analytics['todoPending'] ?? 0;
        _todayTodoCount = analytics['todayTotal'] ?? 0;
        _todayDoneCount = analytics['todayDone'] ?? 0;
        _todayPendingCount = _todayTodoCount - _todayDoneCount;
      });
    } catch (_) {}
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
    final displayName = user == null ? '파일럿' : '${user.email?.split('@').first ?? '파일럿'} 캡틴';
    final progress = (_guidelineCount + _curriculumCount + _doneTodoCount) == 0
        ? 0.18
        : (_doneTodoCount / ((_curriculumCount * 3) + 1)).clamp(0.18, 0.92);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF0066FF), width: 2),
                  gradient: const LinearGradient(colors: [Color(0xFFEAF2FF), Color(0xFFD9EAFF)]),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person_rounded, color: Color(0xFF0050CB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('웰컴 백', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.lightMuted)),
                    Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFE8EDF3)),
                icon: const Icon(Icons.notifications_rounded, color: AppColors.lightText),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => context.go('/search'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.deepBlue),
                  SizedBox(width: 12),
                  Expanded(child: Text('학습 자료를 검색해봐', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightMuted))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0x66DAE1FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x1A0066FF)),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('현재 고도', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
                      const SizedBox(height: 6),
                      Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.lightText)),
                      const SizedBox(height: 6),
                      const Text('목표 도달 중', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightMuted)),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Icon(Icons.trending_up_rounded, size: 16, color: AppColors.primaryStrong),
                          SizedBox(width: 6),
                          Text('지난주 대비 +5% 상승', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryStrong)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ProgressRing(progress: progress),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/todos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0050CB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('비행 재개하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('오늘의 비행 계획', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.lightText)),
          ),
          const SizedBox(height: 12),
          _FlightPlanCard(
            title: '가이드라인 정리',
            subtitle: '오전 경로',
            status: _guidelineCount > 0 ? '완료' : '대기',
            accent: _guidelineCount > 0 ? Colors.green : Colors.grey,
            icon: _guidelineCount > 0 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          ),
          const SizedBox(height: 10),
          _FlightPlanCard(
            title: '학습 탭 점검',
            subtitle: '낮 전이 (현재 위치)',
            status: _todoInProgressCount > 0 ? '진행 중' : '확인 필요',
            accent: const Color(0xFF0050CB),
            icon: Icons.radar_rounded,
            highlighted: true,
          ),
          const SizedBox(height: 10),
          _FlightPlanCard(
            title: '오늘 할 일 정리',
            subtitle: '도착 전략',
            status: _todayPendingCount > 0 ? '대기' : '완료',
            accent: _todayPendingCount > 0 ? const Color(0xFF9CA3AF) : Colors.green,
            icon: _todayPendingCount > 0 ? Icons.lock_outline_rounded : Icons.check_circle_rounded,
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('다음 할 일', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.lightText)),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x4DC2C6D8)),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(value: false, onChanged: (_) {}),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('오늘 남은 Todo 처리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                      Text('오늘 미완료 ${_todayPendingCount > 0 ? _todayPendingCount : _todoPendingCount}개 확인', style: const TextStyle(fontSize: 13, color: AppColors.lightMuted)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFFDAD6), borderRadius: BorderRadius.circular(999)),
                            child: const Text('Emergency', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF93000A))),
                          ),
                          Text('${_todayPendingCount > 0 ? _todayPendingCount : _todoPendingCount}개 남음', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFBA1A1A))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('주요 마일스톤', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                ),
              ),
              TextButton(onPressed: () => context.go('/calendar'), child: const Text('모두 보기')),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _MilestoneCard(date: 'TODAY', title: '커리큘럼 점검', subtitle: '선택된 학습 흐름 확인', accent: AppColors.primaryStrong),
                _MilestoneCard(date: 'THIS WEEK', title: '할일 정리', subtitle: '주간 실행 계획 마감', accent: const Color(0xFF445A7F)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('발견된 리소스', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.lightText)),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.go('/search'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFF284B7A), Color(0xFF0F172A)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('이번 주 수집', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('검색 자료 $_searchCount건', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  const _ProgressRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: const Color(0xFFE0E3E5),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF0050CB)),
            ),
          ),
          const Icon(Icons.rocket_launch_rounded, color: AppColors.primaryStrong),
        ],
      ),
    );
  }
}

class _FlightPlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color accent;
  final IconData icon;
  final bool highlighted;
  const _FlightPlanCard({required this.title, required this.subtitle, required this.status, required this.accent, required this.icon, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlighted ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: highlighted ? const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))] : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: highlighted ? accent : AppColors.lightMuted)),
                const SizedBox(height: 4),
                Text(title, style: TextStyle(fontSize: highlighted ? 18 : 16, fontWeight: FontWeight.w800, color: AppColors.lightText)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent)),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final String date;
  final String title;
  final String subtitle;
  final Color accent;
  const _MilestoneCard({required this.date, required this.title, required this.subtitle, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(20), border: Border(top: BorderSide(color: accent, width: 4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: accent)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.lightText)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
        ],
      ),
    );
  }
}
