import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/planner_service.dart';

class ProductivityPage extends StatefulWidget {
  const ProductivityPage({super.key});

  @override
  State<ProductivityPage> createState() => _ProductivityPageState();
}

class _ProductivityPageState extends State<ProductivityPage> {
  int _sec = 25 * 60;
  bool _running = false;
  Timer? _timer;
  final _habit = TextEditingController(text: '코딩 집중');
  final _minutes = TextEditingController(text: '60');

  @override
  void dispose() {
    _timer?.cancel();
    _habit.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_sec <= 0) {
        t.cancel();
        setState(() => _running = false);
        return;
      }
      setState(() => _sec--);
    });
  }

  Future<void> _logHabit() async {
    final m = int.tryParse(_minutes.text) ?? 0;
    await PlannerService.logHabit(
        habitName: _habit.text.trim(), date: DateTime.now(), minutes: m);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('습관 로그 저장 완료')));
      setState(() {});
    }
  }

  Future<void> _autoReplan() async {
    final moved = await PlannerService.autoReplanOverdueTodos();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지연 Todo $moved개를 내일로 재배치했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_sec ~/ 60).toString().padLeft(2, '0');
    final ss = (_sec % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('실행력 기능')),
      body: FutureBuilder(
        future: PlannerService.listHabitLogs(),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? const <Map<String, dynamic>>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pomodoro 타이머',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('$mm:$ss',
                            style: const TextStyle(
                                fontSize: 34, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Row(children: [
                          ElevatedButton(
                              onPressed: _toggleTimer,
                              child: Text(_running ? '일시정지' : '시작')),
                          const SizedBox(width: 8),
                          OutlinedButton(
                              onPressed: () => setState(() => _sec = 25 * 60),
                              child: const Text('리셋')),
                        ])
                      ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('습관 트래커',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(
                            controller: _habit,
                            decoration:
                                const InputDecoration(labelText: '습관 이름')),
                        const SizedBox(height: 8),
                        TextField(
                            controller: _minutes,
                            decoration: const InputDecoration(
                                labelText: '오늘 집중 시간(분)')),
                        const SizedBox(height: 8),
                        ElevatedButton(
                            onPressed: _logHabit,
                            child: const Text('오늘 로그 저장')),
                      ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_fix_high),
                  title: const Text('주간 자동 재계획'),
                  subtitle: const Text('지연 Todo를 자동으로 다음날로 이동'),
                  trailing: TextButton(
                      onPressed: _autoReplan, child: const Text('실행')),
                ),
              ),
              const SizedBox(height: 12),
              const Text('최근 습관 로그',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              ...logs.take(12).map((e) => ListTile(
                    title: Text((e['habit_name'] ?? '-').toString()),
                    subtitle: Text('${e['log_date']} · ${e['minutes']}분'),
                  )),
            ],
          );
        },
      ),
    );
  }
}
