import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _idCtrl.text = 'admin';
    _pwCtrl.text = 'admin';
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) {
    final m = e.toString().toLowerCase();
    if (m.contains('invalid login credentials')) {
      return '아이디 또는 비밀번호가 올바르지 않아.';
    }
    if (m.contains('email not confirmed')) return '이메일 인증이 필요해.';
    if (m.contains('user already registered')) return '이미 가입된 계정이야.';
    if (m.contains('password')) return '비밀번호 규칙을 다시 확인해줘.';
    return '요청 처리 중 오류가 발생했어.';
  }

  Future<void> _run(Future<void> Function() task,
      {String ok = '완료', bool goHome = false}) async {
    setState(() => _loading = true);
    try {
      await task();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      if (goHome) context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDCEEFF), Color(0xFFF7F9FB), Color(0xFFE9F1FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  decoration: AppTheme.glassCard(highlight: true),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6FCEFE), Color(0xFF0050CB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x220050CB),
                                blurRadius: 24,
                                offset: Offset(0, 12),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.flight_takeoff_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          '스터디 파일럿',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.lightText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          '오늘의 학습 여정을 시작해보자.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        '로그인 정보',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _idCtrl,
                        decoration: const InputDecoration(
                          labelText: '아이디 또는 이메일',
                          hintText: '예: admin 또는 user@example.com',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pwCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '비밀번호'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading
                              ? null
                              : () => _run(
                                    () async {
                                      await AuthService.signInWithPassword(
                                        idOrEmail: _idCtrl.text,
                                        password: _pwCtrl.text,
                                      );
                                    },
                                    ok: '로그인 성공',
                                    goHome: true,
                                  ),
                          child: const Text('로그인'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => _run(
                                    () async {
                                      await AuthService.signUpWithPassword(
                                        idOrEmail: _idCtrl.text,
                                        password: _pwCtrl.text,
                                      );
                                    },
                                    ok: '회원가입 성공',
                                    goHome: true,
                                  ),
                          child: const Text('회원가입'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: AppTheme.glassCard(),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '간편 시작',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () => _run(AuthService.signInWithGoogle,
                                        ok: 'Google 로그인 시작'),
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('Google로 시작하기'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () => _run(AuthService.ensureAdminAccount,
                                        ok: '관리자 계정 로그인 완료', goHome: true),
                                icon: const Icon(Icons.admin_panel_settings_rounded),
                                label: const Text('관리자 계정으로 빠르게 시작'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => _run(AuthService.signOut, ok: '로그아웃 완료'),
                        child: const Text('현재 세션 로그아웃'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '아이디만 입력하면 내부적으로 @guiculum.local 이메일로 변환해서 사용해.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
