import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../services/planner_service.dart';
import '../../services/search_service.dart';

class SearchDetailPage extends StatefulWidget {
  final String itemId;

  const SearchDetailPage({super.key, required this.itemId});

  @override
  State<SearchDetailPage> createState() => _SearchDetailPageState();
}

class _SearchDetailPageState extends State<SearchDetailPage> {
  bool _bookmarked = false;
  bool _bookmarkLoading = true;
  String? _selectedCurriculumId;
  String? _selectedTodoId;

  @override
  void initState() {
    super.initState();
    _loadBookmarkState();
  }

  Future<void> _loadBookmarkState() async {
    final bookmarked = await SearchService.isBookmarked(widget.itemId);
    if (!mounted) return;
    setState(() {
      _bookmarked = bookmarked;
      _bookmarkLoading = false;
    });
  }

  Future<void> _toggleBookmark(SearchItemDto item) async {
    await SearchService.toggleBookmark(item);
    if (!mounted) return;
    setState(() => _bookmarked = !_bookmarked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_bookmarked ? '관심 자료에 저장했어.' : '관심 자료에서 뺐어.')),
    );
  }

  Future<void> _linkToCurriculum(SearchItemDto item, List<Map<String, dynamic>> curriculums) async {
    if (_selectedCurriculumId == null) return;
    final target = curriculums.firstWhere((c) => c['id'] == _selectedCurriculumId);
    await SearchService.saveLink(
      itemId: item.id,
      targetType: 'curriculum',
      targetId: target['id'] as String,
      targetTitle: (target['title'] as String?) ?? '-',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이 자료를 커리큘럼에 연결했어.')),
    );
    setState(() {});
  }

  Future<void> _linkToTodo(SearchItemDto item, List<Map<String, dynamic>> todos) async {
    if (_selectedTodoId == null) return;
    final target = todos.firstWhere((t) => t['id'] == _selectedTodoId);
    await SearchService.saveLink(
      itemId: item.id,
      targetType: 'todo',
      targetId: target['id'] as String,
      targetTitle: (target['title'] as String?) ?? '-',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이 자료를 투두에 연결했어.')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: Future.wait([
          SearchService.getSearchItemById(widget.itemId),
          SearchService.getBookmarks(),
          PlannerService.listCurriculums(),
          PlannerService.listTodos(),
          SearchService.getLinksForItem(widget.itemId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassCard(),
                child: Text('상세 조회 실패: ${snapshot.error}'),
              ),
            );
          }

          final item = snapshot.data?[0] as SearchItemDto?;
          final bookmarks = (snapshot.data?[1] as List<SearchBookmarkDto>?) ?? const [];
          final curriculums = (snapshot.data?[2] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          final todos = (snapshot.data?[3] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          final links = (snapshot.data?[4] as List<SearchLinkDto>?) ?? const [];
          if (item == null) {
            return const Center(child: Text('해당 항목을 찾지 못했어.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
            children: [
              Container(
                decoration: AppTheme.glassCard(highlight: true),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('검색 상세', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
                    const SizedBox(height: 8),
                    Text(item.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.lightText)),
                    const SizedBox(height: 10),
                    Text(item.subtitle ?? '이 항목과 연결된 추가 설명이 여기에 표시돼.', style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.lightMuted)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ActionChip(
                          icon: Icons.copy_rounded,
                          label: 'ID 복사',
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: item.id));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('아이템 ID를 복사했어.')));
                            }
                          },
                        ),
                        _ActionChip(
                          icon: _bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          label: _bookmarkLoading ? '불러오는 중...' : (_bookmarked ? '관심 자료 해제' : '관심 자료 저장'),
                          onTap: _bookmarkLoading ? null : () => _toggleBookmark(item),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: AppTheme.glassCard(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('학습 계획에 연결하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCurriculumId,
                      items: curriculums
                          .map((c) => DropdownMenuItem<String>(value: c['id'] as String, child: Text(c['title'] ?? '-')))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCurriculumId = v),
                      decoration: const InputDecoration(labelText: '연결할 커리큘럼 선택'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: curriculums.isEmpty || _selectedCurriculumId == null ? null : () => _linkToCurriculum(item, curriculums),
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('커리큘럼에 자료 연결'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTodoId,
                      items: todos
                          .map((t) => DropdownMenuItem<String>(value: t['id'] as String, child: Text(t['title'] ?? '-')))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTodoId = v),
                      decoration: const InputDecoration(labelText: '연결할 투두 선택'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: todos.isEmpty || _selectedTodoId == null ? null : () => _linkToTodo(item, todos),
                        icon: const Icon(Icons.checklist_rounded),
                        label: const Text('투두에 자료 연결'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: AppTheme.glassCard(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('연결된 학습 계획', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if (links.isEmpty)
                      const Text('아직 연결된 커리큘럼이나 투두가 없어. 필요한 학습 계획과 바로 이어줘.')
                    else
                      ...links.map((link) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _InfoRow(
                              label: link.targetType == 'curriculum' ? '커리큘럼' : '투두',
                              value: link.targetTitle,
                            ),
                          )),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: AppTheme.glassCard(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('항목 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    _InfoRow(label: '아이템 ID', value: item.id),
                    _InfoRow(label: '제목', value: item.title),
                    _InfoRow(label: '부가 설명', value: item.subtitle ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: AppTheme.glassCard(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('관심 자료 ${bookmarks.length}개', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if (bookmarks.isEmpty)
                      const Text('아직 저장한 검색 자료가 없어. 필요한 항목을 모아두면 학습 흐름 연결할 때 편해져.')
                    else
                      ...bookmarks.take(3).map(
                        (bookmark) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _InfoRow(label: bookmark.title, value: bookmark.subtitle ?? bookmark.id),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primaryStrong),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.lightText)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightText)),
        ],
      ),
    );
  }
}
