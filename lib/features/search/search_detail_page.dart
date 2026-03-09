import 'package:flutter/material.dart';

import '../../services/search_service.dart';

class SearchDetailPage extends StatelessWidget {
  final String itemId;

  const SearchDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Detail')),
      body: FutureBuilder(
        future: SearchService.getSearchItemById(itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('상세 조회 실패: ${snapshot.error}'));
          }

          final item = snapshot.data;
          if (item == null) {
            return const Center(child: Text('해당 항목을 찾지 못했습니다.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                  title: const Text('ID'), subtitle: SelectableText(item.id)),
              ListTile(title: const Text('Title'), subtitle: Text(item.title)),
              ListTile(
                title: const Text('Subtitle'),
                subtitle: Text(item.subtitle ?? '-'),
              ),
            ],
          );
        },
      ),
    );
  }
}
