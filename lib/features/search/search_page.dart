import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';

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
    // Rx는 전체 상태관리 대체가 아니라, 검색 입력 스트림 처리에만 제한 적용
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
      // 로컬 fallback: Supabase 테이블/RLS 미준비 상태에서도 데모 동작 보장
      await Future.delayed(const Duration(milliseconds: 250));
      return List.generate(
        6,
        (i) => SearchItemDto(
          id: 'fallback-$i',
          title: '$query result ${i + 1} (fallback)',
          subtitle: 'local fallback item',
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
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search (Rx stream demo)',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: '검색어'),
              onChanged: _querySubject.add,
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('오류: $_error',
                    style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다.'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = _results[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.search),
                            title: Text(item.title),
                            subtitle: Text(
                                item.subtitle ?? 'Supabase/RxDart result item'),
                            onTap: () => context.go(
                              '/search/${Uri.encodeComponent(item.id)}',
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
