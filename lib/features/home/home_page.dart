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
  DateTime? _lastSignedInAt;
  int _searchCount = 0;
  int _guidelineCount = 0;
  int _curriculumCount = 0;
  int _doneTodoCount = 0;
  int _todoTotalCount = 0;
  int _todoInProgressCount = 0;
  int _todoPendingCount = 0;
  int _todayTodoCount = 0;
  int _todayDoneCount = 0;
  int _todayPendingCount = 0;
  List<Map<String, dynamic>> _weekActivity = const [];
  List<Map<String, dynamic>> _curriculumProgress = const [];

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
          const SnackBar(content: Text('로그인 성공! 프로필을 동기화하는 중이야.')),
        );
      } else if (state.event == AuthChangeEvent.signedOut) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃되었어.')),
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
      final analytics = await PlannerService.dashboardAnalytics();
      if (!mounted) return;
      setState(() {
        _searchCount = planner['search_count'] ?? count;
        _guidelineCount = planner['guidelines'] ?? 0;
        _curriculumCount = planner['curriculums'] ?? 0;
        _doneTodoCount = planner['todos_done'] ?? 0;
        _todoTotalCount = analytics['todoTotal'] ?? 0;
        _todoInProgressCount = analytics['todoInProgress'] ?? 0;
        _todoPendingCount = analytics['todoPending'] ?? 0;
        _todayTodoCount = analytics['todayTotal'] ?? 0;
        _todayDoneCount = analytics['todayDone'] ?? 0;
        _todayPendingCount = _todayTodoCount - _todayDoneCount;
        _weekActivity = (analytics['weekActivity'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        _curriculumProgress = (analytics['curriculumProgress'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      });
    } catch (_) {}
  }

  String _formatLastSignedIn() {
    if (_lastSignedInAt == null) return '-';
    final dt = _lastSignedInAt!;
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
    final progress = (_guidelineCount + _curriculumCount + _doneTodoCount) == 0
        ? 0.18
        : (_doneTodoCount / ((_curriculumCount * 3) + 1)).clamp(0.18, 0.92);
    final needsOnboarding = user != null && _guidelineCount == 0 && _curriculumCount == 0 && _todoTotalCount == 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
        children: [
          Container(
            decoration: AppTheme.glassCard(highlight: true),
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '웰컴 백',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user == null ? '학습 여정을 시작해볼까?' : '${user.email?.split('@').first ?? '파일럿'} 캡틴',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user == null
                            ? '로그인하고 나만의 학습 항로를 설정해줘.'
                            : '오늘의 비행 계획을 점검하고 다음 목표를 이어가자.',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.lightMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _MiniPill(
                            icon: Icons.bolt_rounded,
                            label: user == null ? '비로그인 상태' : '세션 활성',
                          ),
                          const SizedBox(width: 8),
                          _MiniPill(
                            icon: Icons.schedule_rounded,
                            label: user == null ? '로그인 후 기록 표시' : '최근 로그인 ${_formatLastSignedIn()}',
                          ),
                        ],
                      ),
                      if (user == null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('로그인하고 시작하기'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _ProgressDial(progress: progress),
              ],
            ),
          ),
          if (needsOnboarding) ...[
            const SizedBox(height: 18),
            Container(
              decoration: AppTheme.glassCard(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('첫 학습 시작 가이드', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  const Text(
                    '아직 비어 있으니까 순서대로 한 번만 만들면 바로 학습 흐름이 잡혀. 목표를 정하고 첫 계획과 첫 실행 항목까지 이어가자.',
                    style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.lightMuted),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      _OnboardingStepTile(step: '1', title: '가이드라인 만들기', subtitle: '목표 직무와 학습 원칙부터 정리', onTap: () => context.go('/guidelines')),
                      const SizedBox(height: 10),
                      _OnboardingStepTile(step: '2', title: '커리큘럼 설계', subtitle: '학습 기간과 계획 구조 잡기', onTap: () => context.go('/curriculums')),
                      const SizedBox(height: 10),
                      _OnboardingStepTile(step: '3', title: '첫 투두 등록', subtitle: '오늘 바로 실행할 첫 항목 만들기', onTap: () => context.go('/todos')),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (user != null && (_todayPendingCount > 0 || _todoInProgressCount > 0)) ...[
            const SizedBox(height: 18),
            Container(
              decoration: AppTheme.glassCard(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('오늘의 리마인드', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                    _todayPendingCount > 0
                        ? '오늘 아직 $_todayPendingCount개 남아 있어. 지금 투두 캘린더로 가서 하나씩 처리해보자.'
                        : '오늘 마감은 다 끝냈고, 진행 중인 일정 $_todoInProgressCount개를 마무리하면 좋아.',
                    style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.lightMuted),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MiniStatCard(label: '오늘 미완료', value: '$_todayPendingCount'),
                      _MiniStatCard(label: '진행중', value: '$_todoInProgressCount'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/todos'),
                      icon: const Icon(Icons.notifications_active_rounded),
                      label: const Text('오늘 할 일 점검하러 가기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: '가이드라인',
                  value: '$_guidelineCount',
                  hint: '학습 방향 수',
                  icon: Icons.route_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: '커리큘럼',
                  value: '$_curriculumCount',
                  hint: '운항 중 계획',
                  icon: Icons.map_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: '완료한 투두',
                  value: '$_doneTodoCount',
                  hint: '오늘까지 누적',
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: '검색 인덱스',
                  value: '$_searchCount',
                  hint: '탐색 가능한 자료',
                  icon: Icons.search_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: AppTheme.glassCard(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('실행 통계', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MiniStatCard(label: '전체 투두', value: '$_todoTotalCount'),
                    _MiniStatCard(label: '진행중', value: '$_todoInProgressCount'),
                    _MiniStatCard(label: '대기', value: '$_todoPendingCount'),
                    _MiniStatCard(label: '오늘 할 일', value: '$_todayTodoCount'),
                    _MiniStatCard(label: '오늘 완료', value: '$_todayDoneCount'),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('최근 7일 실행량', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (_weekActivity.isEmpty)
                  const Text('최근 7일 데이터가 아직 없어.', style: TextStyle(color: AppColors.lightMuted))
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _weekActivity.map((item) {
                      final count = (item['count'] as int?) ?? 0;
                      final maxCount = _weekActivity.fold<int>(0, (mx, e) => (((e['count'] as int?) ?? 0) > mx ? ((e['count'] as int?) ?? 0) : mx));
                      final height = maxCount == 0 ? 12.0 : (20 + (count / maxCount) * 60);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Text('$count', style: const TextStyle(fontSize: 11, color: AppColors.lightMuted)),
                              const SizedBox(height: 6),
                              Container(
                                height: height,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F8CFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text((item['date'] as String).substring(5), style: const TextStyle(fontSize: 10, color: AppColors.lightMuted)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                const Text('커리큘럼별 진척률', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (_curriculumProgress.isEmpty)
                  const Text('아직 커리큘럼 진척 데이터가 없어.', style: TextStyle(color: AppColors.lightMuted))
                else
                  ..._curriculumProgress.take(3).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProgressSummaryTile(
                          title: (item['title'] as String?) ?? '-',
                          done: (item['done'] as int?) ?? 0,
                          total: (item['total'] as int?) ?? 0,
                          progress: ((item['progress'] as num?) ?? 0).toDouble(),
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: AppTheme.glassCard(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '빠른 이동',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _QuickActionButton(label: '가이드라인 만들기', icon: Icons.route_rounded, onTap: () => context.go('/guidelines')),
                    _QuickActionButton(label: '커리큘럼 설계', icon: Icons.map_rounded, onTap: () => context.go('/curriculums')),
                    _QuickActionButton(label: '투두 캘린더', icon: Icons.checklist_rounded, onTap: () => context.go('/todos')),
                    _QuickActionButton(label: '학습 캘린더', icon: Icons.calendar_month_rounded, onTap: () => context.go('/calendar')),
                    _QuickActionButton(label: '자료 검색', icon: Icons.search_rounded, onTap: () => context.go('/search')),
                    _QuickActionButton(label: '마이페이지', icon: Icons.person_rounded, onTap: () => context.go('/profile')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: AppTheme.glassCard(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '비행 현황',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _StatusTile(
                  icon: Icons.route_rounded,
                  title: '핵심 플로우',
                  subtitle: '가이드라인 $_guidelineCount → 커리큘럼 $_curriculumCount → 완료된 투두 $_doneTodoCount',
                ),
                const SizedBox(height: 10),
                _StatusTile(
                  icon: Icons.person_outline_rounded,
                  title: '프로필 상태',
                  subtitle: user == null ? '로그인이 필요해.' : (user.email ?? user.id),
                  onTap: user == null ? () => context.go('/login') : () => context.go('/profile'),
                ),
                const SizedBox(height: 10),
                _StatusTile(
                  icon: Icons.search_rounded,
                  title: '탐색 상태',
                  subtitle: '검색 인덱스 항목 수 $_searchCount개',
                  onTap: () => context.go('/search'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.deepBlue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDial extends StatelessWidget {
  final double progress;
  const _ProgressDial({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 108,
            height: 108,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF0066FF)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.lightText,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '현재 고도',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final IconData icon;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primaryStrong),
          ),
          const SizedBox(height: 14),
          Text(label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.lightMuted,
              )),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.lightText,
              )),
          const SizedBox(height: 4),
          Text(hint,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.lightMuted,
              )),
        ],
      ),
    );
  }
}





class _OnboardingStepTile extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _OnboardingStepTile({required this.step, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF4F8CFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(step, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.lightMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.lightMuted),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.lightText)),
        ],
      ),
    );
  }
}

class _ProgressSummaryTile extends StatelessWidget {
  final String title;
  final int done;
  final int total;
  final double progress;
  const _ProgressSummaryTile({required this.title, required this.done, required this.total, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightText))),
              Text('$done/$total', style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(999)),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryStrong),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.lightText)),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _StatusTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primaryStrong),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.lightMuted)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.lightMuted),
          ],
        ),
      ),
    );
  }
}
