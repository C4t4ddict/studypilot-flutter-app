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
  bool _saving = false;
  int _refreshTick = 0;
  String? _optimisticNickname;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
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
          if (_nicknameCtrl.text.isEmpty) {
            _nicknameCtrl.text = currentNickname;
          }

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
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '파일럿 프로필',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.deepBlue,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentNickname,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.lightText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.lightMuted,
                                  ),
                                ),
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
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: AppColors.lightMuted,
                          ),
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
                      const Text(
                        '계정 정보',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
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
                      const Text(
                        '프로필 설정',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.lightMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}
