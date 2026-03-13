import 'package:flutter/material.dart';
import '../../services/planner_service.dart';

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  static const templates = [
    {
      'role': 'Frontend Developer',
      'title': '프론트엔드 취업 12주 템플릿',
      'notes': 'React/TS 포트폴리오 + 면접 대비 + 이력서 최적화',
    },
    {
      'role': 'Flutter Developer',
      'title': 'Flutter 앱 취업 10주 템플릿',
      'notes': '실전 앱 2개 + 상태관리 + 배포 + 테스트',
    },
    {
      'role': 'Backend Developer',
      'title': '백엔드 취업 12주 템플릿',
      'notes': 'API 설계/인증/배포/성능/모니터링',
    },
    {
      'role': 'Data Analyst',
      'title': '데이터 직무 12주 템플릿',
      'notes': 'SQL/통계/대시보드/실험설계/포트폴리오 프로젝트',
    },
  ];

  Future<void> _apply(BuildContext context, Map<String, String> t) async {
    await PlannerService.createGuideline(
      role: t['role']!,
      title: t['title']!,
      notes: t['notes']!,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('템플릿 적용 완료: ${t['title']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('직무 템플릿')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('빠른 시작 템플릿',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...templates.map((t) => Card(
                child: ListTile(
                  title: Text(t['title']!),
                  subtitle: Text('${t['role']}\n${t['notes']}'),
                  trailing: TextButton(
                    onPressed: () => _apply(context, t.cast<String, String>()),
                    child: const Text('적용'),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
