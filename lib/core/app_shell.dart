import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_theme.dart';
import 'theme_controller.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _items = [
    _NavItem(label: '대시보드', icon: Icons.home_rounded, path: '/'),
    _NavItem(label: '가이드라인', icon: Icons.route_rounded, path: '/guidelines'),
    _NavItem(label: '커리큘럼', icon: Icons.map_rounded, path: '/curriculums'),
    _NavItem(label: '학습 캘린더', icon: Icons.calendar_month_rounded, path: '/calendar'),
    _NavItem(label: '투두 캘린더', icon: Icons.checklist_rounded, path: '/todos'),
    _NavItem(label: '검색', icon: Icons.search_rounded, path: '/search'),
    _NavItem(label: '마이페이지', icon: Icons.person_rounded, path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).matchedLocation;
    final title = _items
        .firstWhere(
          (item) => current == item.path || current.startsWith('${item.path}/'),
          orElse: () => _items.first,
        )
        .label;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDCEEFF), Color(0xFFF7F9FB), Color(0xFFEAF2FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopHeader(title: title),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: child,
                ),
              ),
              _BottomNav(currentPath: current),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  const _TopHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        decoration: AppTheme.glassCard(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6FCEFE), Color(0xFF0050CB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Study Pilot',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '테마 전환',
              onPressed: toggleThemeMode,
              icon: Icon(
                themeModeNotifier.value == ThemeMode.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: AppColors.deepBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final String currentPath;
  const _BottomNav({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Container(
        decoration: AppTheme.glassCard(highlight: true),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: AppShell._items.map((item) {
            final active = currentPath == item.path || currentPath.startsWith('${item.path}/');
            return Expanded(
              child: InkWell(
                onTap: () => context.go(item.path),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: active
                              ? const Color(0xFF0066FF)
                              : Colors.white.withValues(alpha: 0.38),
                        ),
                        child: Icon(
                          item.icon,
                          size: 22,
                          color: active ? Colors.white : AppColors.deepBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                          color: active ? AppColors.primaryStrong : AppColors.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem({required this.label, required this.icon, required this.path});
}
