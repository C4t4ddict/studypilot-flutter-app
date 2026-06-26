import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/app_theme.dart';
import '../../services/search_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _querySubject = BehaviorSubject<String>();
  late final StreamSubscription<List<SearchItemDto>> _sub;
  List<SearchItemDto> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = _querySubject
        .debounceTime(const Duration(milliseconds: 350))
        .distinct()
        .switchMap((q) {
      if (mounted) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }
      return Stream.fromFuture(_search(q));
    }).listen((items) {
      if (mounted) {
        setState(() {
          _results = items;
          _loading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    });
  }

  Future<List<SearchItemDto>> _search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      return await SearchService.searchItems(query);
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 250));
      return List.generate(
        6,
        (i) => SearchItemDto(
          id: 'fallback-$i',
          title: '$query 검색 결과 ${i + 1}',
          subtitle: '임시 로컬 결과 항목',
        ),
      );
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _querySubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: AppTheme.glassCard(highlight: true),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '자료 탐색',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '검색 스테이션',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '학습에 필요한 자료와 키워드를 빠르게 탐색하고, 필요한 항목을 자세히 열어볼 수 있어.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.lightMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: '예: Flutter 상태관리, 포트폴리오, 면접 준비',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: _querySubject.add,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: LinearProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                child: Text('오류: $_error',
                    style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 14),
            Expanded(
              child: _results.isEmpty
                  ? Container(
                      width: double.infinity,
                      decoration: AppTheme.glassCard(),
                      padding: const EdgeInsets.all(24),
                      child: const Center(
                        child: Text(
                          '검색어를 입력하면 관련 학습 자료를 여기서 보여줄게.',
                          style: TextStyle(color: AppColors.lightMuted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = _results[i];
                        return InkWell(
                          onTap: () => context.go(
                            '/search/${Uri.encodeComponent(item.id)}',
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: AppTheme.glassCard(),
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.48),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.travel_explore_rounded,
                                      color: AppColors.primaryStrong),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.lightText,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.subtitle ?? '연결 가능한 학습 자료 항목',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.lightMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.lightMuted),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
