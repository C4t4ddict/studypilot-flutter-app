import 'package:flutter/material.dart';

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
          content: const Text('닉네임이 저장되었습니다.'),
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
      appBar: AppBar(title: const Text('My Profile')),
      body: FutureBuilder(
        future: Future.value(_refreshTick)
            .then((_) => ProfileService.fetchMyProfile()),
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
            onRefresh: () async {
              setState(() => _refreshTick++);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(title: const Text('ID'), subtitle: Text(p.id)),
                ListTile(title: const Text('Email'), subtitle: Text(p.email)),
                ListTile(
                  title: const Text('Current Nickname'),
                  subtitle: Text(currentNickname),
                ),
                ListTile(
                    title: const Text('Created'), subtitle: Text(p.createdAt)),
                const SizedBox(height: 12),
                TextField(
                  controller: _nicknameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _saving ? null : _saveNickname,
                  child: Text(_saving ? '저장 중...' : '닉네임 저장'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
