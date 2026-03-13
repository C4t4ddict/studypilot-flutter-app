import 'package:flutter/material.dart';

import '../../services/planner_service.dart';

class CareerPage extends StatefulWidget {
  const CareerPage({super.key});

  @override
  State<CareerPage> createState() => _CareerPageState();
}

class _CareerPageState extends State<CareerPage> {
  final _checkTitle = TextEditingController();
  final _q = TextEditingController();
  final _a = TextEditingController();
  final _f = TextEditingController();
  final _company = TextEditingController();
  final _version = TextEditingController();
  final _notes = TextEditingController();
  String _category = '기획';

  Future<void> _refresh() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('취업 준비 보드')),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          PlannerService.listPortfolioChecklist(),
          PlannerService.listInterviewCards(),
          PlannerService.listResumeVersions(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final checklist = snapshot.data![0] as List<Map<String, dynamic>>;
          final interviews = snapshot.data![1] as List<Map<String, dynamic>>;
          final resumes = snapshot.data![2] as List<Map<String, dynamic>>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('포트폴리오 체크리스트',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                DropdownButton<String>(
                  value: _category,
                  items: const ['기획', '구현', '배포', '회고', '문서']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? '기획'),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _checkTitle,
                        decoration:
                            const InputDecoration(hintText: '예) README 정리'))),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: () async {
                      if (_checkTitle.text.trim().isEmpty) return;
                      await PlannerService.addPortfolioChecklist(
                          category: _category, title: _checkTitle.text.trim());
                      _checkTitle.clear();
                      _refresh();
                    },
                    child: const Text('추가')),
              ]),
              ...checklist.take(10).map((e) => CheckboxListTile(
                    value: (e['done'] ?? false) as bool,
                    onChanged: (v) async {
                      await PlannerService.togglePortfolioChecklist(
                          (e['id'] ?? '').toString(), v ?? false);
                      _refresh();
                    },
                    title: Text((e['title'] ?? '-').toString()),
                    subtitle: Text((e['category'] ?? '-').toString()),
                  )),
              const Divider(height: 28),
              const Text('면접 준비 보드',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              TextField(
                  controller: _q,
                  decoration: const InputDecoration(labelText: '질문')),
              TextField(
                  controller: _a,
                  decoration: const InputDecoration(labelText: '답변')),
              TextField(
                  controller: _f,
                  decoration: const InputDecoration(labelText: '모의면접 피드백')),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () async {
                    if (_q.text.trim().isEmpty) return;
                    await PlannerService.addInterviewCard(
                        question: _q.text.trim(),
                        answer: _a.text.trim(),
                        feedback: _f.text.trim());
                    _q.clear();
                    _a.clear();
                    _f.clear();
                    _refresh();
                  },
                  child: const Text('질문 카드 저장')),
              ...interviews.take(8).map((e) => ListTile(
                    title: Text((e['question'] ?? '-').toString()),
                    subtitle: Text(
                        'A: ${(e['answer'] ?? '')}\n피드백: ${(e['mock_feedback'] ?? '')}'),
                  )),
              const Divider(height: 28),
              const Text('이력서/자소서 버전',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              TextField(
                  controller: _company,
                  decoration: const InputDecoration(labelText: '회사명')),
              TextField(
                  controller: _version,
                  decoration:
                      const InputDecoration(labelText: '버전 라벨 (예: v2.1)')),
              TextField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: '커스텀 포인트')),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () async {
                    if (_company.text.trim().isEmpty ||
                        _version.text.trim().isEmpty) {
                      return;
                    }
                    await PlannerService.addResumeVersion(
                        company: _company.text.trim(),
                        versionLabel: _version.text.trim(),
                        notes: _notes.text.trim());
                    _company.clear();
                    _version.clear();
                    _notes.clear();
                    _refresh();
                  },
                  child: const Text('버전 저장')),
              ...resumes.take(8).map((e) => ListTile(
                    title: Text('${e['company']} · ${e['version_label']}'),
                    subtitle: Text((e['notes'] ?? '').toString()),
                  )),
            ],
          );
        },
      ),
    );
  }
}
