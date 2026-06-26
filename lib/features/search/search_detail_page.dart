import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../services/search_service.dart';

class SearchDetailPage extends StatelessWidget {
  final String itemId;

  const SearchDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    const Text(
                      '검색 상세',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.subtitle ?? '이 항목과 연결된 추가 설명이 여기에 표시돼.',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.lightMuted,
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
                    const Text(
                      '항목 정보',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(label: '아이템 ID', value: item.id),
                    _InfoRow(label: '제목', value: item.title),
                    _InfoRow(label: '부가 설명', value: item.subtitle ?? '-'),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.lightMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}
