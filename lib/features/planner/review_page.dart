import 'package:flutter/material.dart';
import '../../services/planner_service.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _week = TextEditingController();
  final _wins = TextEditingController();
  final _lows = TextEditingController();
  final _next = TextEditingController();

  Future<void> _save() async {
    await PlannerService.createWeeklyReview(
      weekLabel: _week.text.trim().isEmpty ? '이번 주' : _week.text.trim(),
      wins: _wins.text.trim(),
      lows: _lows.text.trim(),
      nextPlan: _next.text.trim(),
    );
    _wins.clear();
    _lows.clear();
    _next.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주간 회고')),
      body: FutureBuilder(
        future: PlannerService.listWeeklyReviews(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                  controller: _week,
                  decoration:
                      const InputDecoration(labelText: '주차 라벨 (예: 2026-W11)')),
              const SizedBox(height: 8),
              TextField(
                  controller: _wins,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '잘한 점')),
              const SizedBox(height: 8),
              TextField(
                  controller: _lows,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '아쉬운 점')),
              const SizedBox(height: 8),
              TextField(
                  controller: _next,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '다음 주 개선안')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _save, child: const Text('회고 저장')),
              const Divider(height: 28),
              ...items.map((r) => Card(
                    child: ListTile(
                      title: Text((r['week_label'] ?? '-').toString()),
                      subtitle: Text(
                          '잘한 점: ${(r['wins'] ?? '')}\n개선: ${(r['next_plan'] ?? '')}'),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
