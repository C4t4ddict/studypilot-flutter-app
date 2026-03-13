import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/planner_service.dart';

class OpsPage extends StatefulWidget {
  const OpsPage({super.key});

  @override
  State<OpsPage> createState() => _OpsPageState();
}

class _OpsPageState extends State<OpsPage> {
  Future<List<String>> _upcomingFromTodos() async {
    final todos = await PlannerService.listTodos();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = todos.where((t) {
      final s = (t['status'] ?? 'todo').toString();
      if (s == 'done') return false;
      final d = DateTime.tryParse((t['due_date'] ?? '').toString());
      if (d == null) return false;
      final dd = DateTime(d.year, d.month, d.day);
      return !dd.isBefore(today);
    }).take(8);

    return upcoming
        .map((t) => '${t['title'] ?? '(제목 없음)'} · ${t['due_date'] ?? ''}')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('운영 / 완성도')),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          PlannerService.mentorSharePath(),
          _upcomingFromTodos(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final share = snapshot.data![0] as String;
          final events = snapshot.data![1] as List<String>;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('백업/내보내기 (CSV)'),
                  subtitle: const Text('현재 데이터 스냅샷을 CSV로 클립보드 복사'),
                  trailing: TextButton(
                    onPressed: () async {
                      await PlannerService.exportSnapshotCsvToClipboard();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('CSV를 클립보드에 복사했습니다.')));
                      }
                    },
                    child: const Text('내보내기'),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('멘토 공유 링크'),
                  subtitle: Text('현재 요약 공유 경로: $share'),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.calendar_month_outlined),
                  title: Text('캘린더 연동 (외부 API 미사용 모드)'),
                  subtitle: Text('Google/Apple 연동 없이 Todo 기반 일정만 표시합니다.'),
                ),
              ),
              if (events.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('다가오는 일정',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ...events.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Text('• $e'),
                            )),
                      ],
                    ),
                  ),
                ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('알림 채널'),
                  subtitle: Text(
                      kIsWeb ? '웹 알림/이메일/텔레그램 연동 예정' : '푸시/이메일/텔레그램 연동 예정'),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.devices_outlined),
                  title: Text('다중 기기 동기화'),
                  subtitle: Text('Supabase 실시간 동기화 구조로 확장 가능'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
