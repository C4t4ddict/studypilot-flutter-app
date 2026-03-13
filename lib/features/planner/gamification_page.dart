import 'package:flutter/material.dart';

import '../../services/planner_service.dart';

class GamificationPage extends StatelessWidget {
  const GamificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('동기부여 / 게임화')),
      body: FutureBuilder(
        future: PlannerService.gamificationStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final m = snapshot.data!;
          final streak = (m['streak'] ?? 0).toString();
          final level = (m['level'] ?? 1).toString();
          final badge = (m['badge'] ?? '-').toString();
          final days =
              (m['heatmap_days'] as List?)?.map((e) => e.toString()).toSet() ??
                  <String>{};

          final today = DateTime.now();
          final cells = List.generate(35, (i) {
            final d = DateTime(today.year, today.month, today.day - (34 - i));
            final key = d.toIso8601String().substring(0, 10);
            final on = days.contains(key);
            return Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: on ? Colors.green : Colors.grey.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(spacing: 10, runSpacing: 10, children: [
                _k('연속 달성', '$streak일'),
                _k('레벨', 'Lv.$level'),
                _k('배지', badge),
              ]),
              const SizedBox(height: 16),
              const Text('목표 달성 히트맵 (최근 35일)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(children: cells),
              const SizedBox(height: 16),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.celebration_outlined),
                  title: Text('주간 보상 미션'),
                  subtitle: Text('이번 주 5일 이상 집중 로그 달성 시 보상 배지 획득'),
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
