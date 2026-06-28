import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nicknameCtrl = TextEditingController();
  final _jobGoalCtrl = TextEditingController();
  final _studyStyleCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController();
  bool _saving = false;
  int _refreshTick = 0;
  String? _optimisticNickname;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _jobGoalCtrl.dispose();
    _studyStyleCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    final previous = _optimisticNickname ?? _nicknameCtrl.text;
    final next = _nicknameCtrl.text.trim();

    setState(() {
      _saving = true;
      _optimisticNickname = next;
    });

    try {
      await ProfileService.updateMyNickname(next);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('닉네임 저장 완료'),
          action: SnackBarAction(
            label: '실행 취소',
            onPressed: () async {
              setState(() {
                _optimisticNickname = previous;
                _nicknameCtrl.text = previous;
              });
              try {
                await ProfileService.updateMyNickname(previous);
              } catch (_) {}
            },
          ),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optimisticNickname = previous;
        _nicknameCtrl.text = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveExtras() async {
    setState(() => _saving = true);
    try {
      await ProfileService.updateProfileExtras(
        jobGoal: _jobGoalCtrl.text,
        studyStyle: _studyStyleCtrl.text,
        interests: _interestsCtrl.text.split(','),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학습 설정을 저장했어.')),
      );
      setState(() => _refreshTick++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: Future.value(_refreshTick).then((_) => ProfileService.fetchMyProfile()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('프로필 조회 실패: ${snapshot.error}'));
          }
          final p = snapshot.data;
          if (p == null) {
            return const Center(child: Text('로그인 필요 또는 프로필 없음'));
          }

          final currentNickname = _optimisticNickname ?? p.nickname;
          if (_nicknameCtrl.text.isEmpty) _nicknameCtrl.text = currentNickname;
          if (_jobGoalCtrl.text.isEmpty) _jobGoalCtrl.text = p.jobGoal;
          if (_studyStyleCtrl.text.isEmpty) _studyStyleCtrl.text = p.studyStyle;
          if (_interestsCtrl.text.isEmpty) _interestsCtrl.text = p.interests.join(', ');

          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshTick++),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
              children: [
                Container(
                  decoration: AppTheme.glassCard(highlight: true),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF6FCEFE), Color(0xFF0050CB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('파일럿 프로필', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
                                const SizedBox(height: 6),
                                Text(currentNickname, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.lightText)),
                                const SizedBox(height: 4),
                                Text(p.email, style: const TextStyle(fontSize: 13, color: AppColors.lightMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          '학습 항로를 더 선명하게 만들 수 있도록 닉네임과 개인 설정을 정리해줘. 이후 대시보드와 캘린더 전반에 이 정보가 자연스럽게 녹아들게 돼.',
                          style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.lightMuted),
                        ),
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
                      const Text('학습 방향 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      _InfoRow(label: '목표 직무', value: p.jobGoal.isEmpty ? '아직 설정 안 됨' : p.jobGoal),
                      _InfoRow(label: '학습 스타일', value: p.studyStyle.isEmpty ? '아직 설정 안 됨' : p.studyStyle),
                      _InfoRow(label: '관심 분야', value: p.interests.isEmpty ? '아직 설정 안 됨' : p.interests.join(', ')),
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
                      const Text('계정 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      _InfoRow(label: '프로필 ID', value: p.id),
                      _InfoRow(label: '이메일', value: p.email),
                      _InfoRow(label: '현재 닉네임', value: currentNickname),
                      _InfoRow(label: '생성일', value: p.createdAt),
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
                      const Text('프로필 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nicknameCtrl,
                        decoration: const InputDecoration(
                          labelText: '닉네임',
                          hintText: '앱에서 보여질 이름을 입력해줘',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _saveNickname,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(_saving ? '저장 중...' : '닉네임 저장'),
                        ),
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
                      const Text('학습 설정 확장', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _jobGoalCtrl,
                        decoration: const InputDecoration(
                          labelText: '목표 직무',
                          hintText: '예: Flutter 앱 개발자',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _studyStyleCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: '학습 스타일 메모',
                          hintText: '예: 평일 짧게, 주말 길게 / 실습 위주 선호',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _interestsCtrl,
                        decoration: const InputDecoration(
                          labelText: '관심 분야',
                          hintText: '예: Flutter, UI, Supabase, 알고리즘',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('관심 분야는 쉼표로 구분해서 입력해줘.', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _saveExtras,
                          icon: const Icon(Icons.tune_rounded),
                          label: Text(_saving ? '저장 중...' : '학습 설정 저장'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightText)),
        ],
      ),
    );
  }
}
