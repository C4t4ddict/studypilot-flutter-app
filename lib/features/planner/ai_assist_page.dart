import 'package:flutter/material.dart';

import '../../services/planner_service.dart';

class AiAssistPage extends StatefulWidget {
  const AiAssistPage({super.key});

  @override
  State<AiAssistPage> createState() => _AiAssistPageState();
}

class _AiAssistPageState extends State<AiAssistPage> {
  String _msg = '추천을 불러오려면 버튼을 누르세요.';

  Future<void> _suggest() async {
    final s = await PlannerService.aiSuggestNextStep();
    setState(() => _msg = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 보조 (MVP)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('가이드라인/커리큘럼/투두 추천',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(_msg),
                    const SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: _suggest, child: const Text('다음 액션 추천 받기')),
                  ]),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.auto_awesome_outlined),
              title: Text('향후 확장'),
              subtitle: Text('LLM 기반 초안 추천/회고 요약/다음 주 개선안 자동 생성'),
            ),
          ),
        ],
      ),
    );
  }
}
