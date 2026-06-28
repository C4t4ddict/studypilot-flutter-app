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
      if (!mounted) return;
      setState(() {
        _searchCount = planner['search_count'] ?? count;
        _guidelineCount = planner['guidelines'] ?? 0;
        _curriculumCount = planner['curriculums'] ?? 0;
        _doneTodoCount = planner['todos_done'] ?? 0;
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
