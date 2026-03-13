import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _loading = false;
  bool _agreeTerms = false;
  bool _autoLogin = true;
  bool _signupInFlight = false;
  DateTime? _cooldownUntil;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) {
    final m = e.toString().toLowerCase();
    if (m.contains('user already registered')) {
      return '이미 가입된 계정입니다.';
    }
    if (m.contains('password should be at least')) {
      return '비밀번호는 최소 6자 이상이어야 합니다.';
    }
    if (m.contains('over_email_send_rate_limit') ||
        m.contains('email rate limit exceeded')) {
      return '가입 시도 횟수가 많아 잠시 제한되었습니다. 잠시 후 다시 시도해주세요.';
    }
    return '회원가입 중 오류가 발생했습니다.';
  }

  String _passwordStrength(String pw) {
    if (pw.length < 6) return '약함';
    final hasNum = RegExp(r'[0-9]').hasMatch(pw);
    final hasAlpha = RegExp(r'[A-Za-z]').hasMatch(pw);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(pw);
    final score = [hasNum, hasAlpha, hasSpecial].where((e) => e).length;
    if (pw.length >= 10 && score >= 2) return '강함';
    if (score >= 2) return '보통';
    return '약함';
  }

  Color _strengthColor(String s) {
    if (s == '강함') return Colors.green;
    if (s == '보통') return Colors.orange;
    return Colors.red;
  }

  Future<void> _signup() async {
    final now = DateTime.now();
    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      final sec = _cooldownUntil!.difference(now).inSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('잠시 후 다시 시도해주세요. (${sec}s)')),
      );
      return;
    }

    if (_signupInFlight) return;

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('약관 동의가 필요합니다.')));
      return;
    }
    if (!_idCtrl.text.trim().contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입은 이메일 형식으로 입력해주세요.')));
      return;
    }
    if (_pwCtrl.text != _pw2Ctrl.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('비밀번호 확인이 일치하지 않습니다.')));
      return;
    }

    setState(() {
      _loading = true;
      _signupInFlight = true;
    });
    try {
      final normalized = AuthService.normalizeLoginId(_idCtrl.text);
      debugPrint('[signup] request email=$normalized');
      await AuthService.signUpWithPassword(
          idOrEmail: _idCtrl.text, password: _pwCtrl.text);

      if (_autoLogin) {
        await AuthService.signInWithPassword(
            idOrEmail: _idCtrl.text, password: _pwCtrl.text);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_autoLogin ? '회원가입 + 자동 로그인 완료' : '회원가입 완료. 로그인 해주세요.'),
        ),
      );
      context.go(_autoLogin ? '/' : '/login');
    } catch (e) {
      if (!mounted) return;
      debugPrint('[signup] error=$e');
      final msg = _friendlyError(e);
      if (msg.contains('잠시 제한')) {
        _cooldownUntil = DateTime.now().add(const Duration(seconds: 45));
      }
      final showRaw = kDebugMode ? '\n원문: $e' : '';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$msg$showRaw')));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _signupInFlight = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength(_pwCtrl.text);

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
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
                      hintText: '예: hoya@example.com',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pwCtrl,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: '비밀번호'),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('비밀번호 강도: '),
                      Text(
                        strength,
                        style: TextStyle(
                            color: _strengthColor(strength),
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pw2Ctrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '비밀번호 확인'),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _agreeTerms,
                    onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                    title: const Text('약관 및 개인정보 처리방침에 동의합니다.'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _autoLogin,
                    onChanged: (v) => setState(() => _autoLogin = v),
                    title: const Text('가입 후 자동 로그인'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _signup,
                    child: Text(_loading ? '처리 중...' : '회원가입'),
                  ),
                  if (_cooldownUntil != null &&
                      DateTime.now().isBefore(_cooldownUntil!))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '가입 재시도 대기 중: ${_cooldownUntil!.difference(DateTime.now()).inSeconds}s',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  TextButton(
                    onPressed: _loading ? null : () => context.go('/login'),
                    child: const Text('로그인으로 돌아가기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
