import 'package:flutter/material.dart';
import '../../services/planner_service.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('인사이트 / 리스크 알림')),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          PlannerService.computeRiskInsights(),
          PlannerService.goalProgress(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final m = snapshot.data![0] as Map<String, dynamic>;
          final gp = snapshot.data![1] as Map<String, dynamic>;
          final overdue = (m['overdue'] as int?) ?? 0;
          final dueSoon = (m['due_48h'] as int?) ?? 0;
          final dueToday = (m['due_today'] as int?) ?? 0;
          final dueTomorrow = (m['due_tomorrow'] as int?) ?? 0;
          final inProgress = (m['in_progress'] as int?) ?? 0;
          final doneRate = (m['done_rate'] as double?) ?? 0;
          final align = (m['alignment_score'] as double?) ?? 0;
          final goalRate = (gp['goal_achievement_rate'] as double?) ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _k('지연 Todo', '$overdue'),
                  _k('오늘 마감', '$dueToday'),
                  _k('내일 마감', '$dueTomorrow'),
                  _k('48시간 내 마감', '$dueSoon'),
                  _k('진행중', '$inProgress'),
                  _k('완료율', '${(doneRate * 100).toStringAsFixed(0)}%'),
                  _k('목표 달성률', '${(goalRate * 100).toStringAsFixed(0)}%'),
                  _k('목표-투두 정렬도', '${(align * 100).toStringAsFixed(0)}%'),
                ],
              ),
              const SizedBox(height: 16),
              if (overdue > 0)
                const Card(
                  child: ListTile(
                    leading:
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    title: Text('지연된 할 일이 있습니다'),
                    subtitle: Text('캘린더에서 우선순위를 조정하고 마감일을 재배치하세요.'),
                  ),
                ),
              if (dueSoon > 0)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.notifications_active_outlined),
                    title: Text('마감 임박 알림'),
                    subtitle: Text('오늘/내일 마감 항목을 먼저 처리하세요.'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _k(String t, String v) => SizedBox(
        width: 180,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t),
              const SizedBox(height: 6),
              Text(v,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );
}
