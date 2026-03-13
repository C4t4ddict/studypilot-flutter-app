import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) {
    final m = e.toString().toLowerCase();
    if (m.contains('invalid login credentials')) {
      return '아이디 또는 비밀번호가 올바르지 않습니다.';
    }
    if (m.contains('email not confirmed')) return '이메일 인증이 필요합니다.';
    if (m.contains('user already registered')) return '이미 가입된 계정입니다.';
    if (m.contains('password should be at least')) {
      return '비밀번호는 최소 6자 이상이어야 합니다.';
    }
    if (m.contains('weak password')) return '비밀번호가 너무 약합니다. 6자 이상으로 설정해주세요.';
    if (m.contains('password')) return '비밀번호 규칙을 확인해주세요.';
    return '요청 처리 중 오류가 발생했습니다.';
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
      appBar: AppBar(title: const Text('로그인')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      hintText: '예: user@example.com',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pwCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '비밀번호'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
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
                    child: const Text('일반 로그인'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : () => context.go('/signup'),
                    child: const Text('계정이 없나요? 회원가입'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '비밀번호 규칙: 현재 Supabase 기본 최소 6자 이상',
                    style: TextStyle(fontSize: 12),
                  ),
                  const Divider(height: 24),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () => _run(AuthService.signInWithGoogle,
                            ok: 'Google 로그인 시작'),
                    child: const Text('Google Login'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => _run(AuthService.signOut, ok: '로그아웃 완료'),
                    child: const Text('Logout'),
                  ),
                  const SizedBox(height: 8),
                  const Text('참고: Supabase 이메일 로그인 방식을 사용합니다.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
