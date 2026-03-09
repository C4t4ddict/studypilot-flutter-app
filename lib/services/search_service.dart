import 'package:supabase_flutter/supabase_flutter.dart';

class SearchItemDto {
  final String id;
  final String title;
  final String? subtitle;

  SearchItemDto({required this.id, required this.title, this.subtitle});
}

class SearchService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Supabase 실데이터 검색 예시.
  /// 기본은 public.search_items(title, subtitle) 테이블을 조회한다.
  /// 테이블/권한 미구성 시 에러를 throw하며 상위에서 fallback 처리 가능.
  static Future<List<SearchItemDto>> searchItems(String query) async {
    if (query.trim().isEmpty) return [];

    final data = await _client
        .from('search_items')
        .select('id,title,subtitle')
        .ilike('title', '%$query%')
        .limit(10);

    return (data as List)
        .map((e) => e as Map<String, dynamic>)
        .map((m) => SearchItemDto(
              id: (m['id'] as String?) ?? '',
              title: (m['title'] as String?) ?? '-',
              subtitle: m['subtitle'] as String?,
            ))
        .toList();
  }

  static Future<SearchItemDto?> getSearchItemById(String id) async {
    final data = await _client
        .from('search_items')
        .select('id,title,subtitle')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return SearchItemDto(
      id: (data['id'] as String?) ?? '',
      title: (data['title'] as String?) ?? '-',
      subtitle: data['subtitle'] as String?,
    );
  }

  static Future<int> getSearchItemCount() async {
    final res = await _client
        .from('search_items')
        .select('id')
        .count(CountOption.exact);
    return res.count;
  }
}
