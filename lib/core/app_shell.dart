import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_theme.dart';
import 'theme_controller.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _items = [
    _NavItem(label: '홈', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, path: '/'),
    _NavItem(label: '학습', icon: Icons.import_contacts_outlined, activeIcon: Icons.import_contacts_rounded, path: '/guidelines'),
    _NavItem(label: '캘린더', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, path: '/calendar'),
    _NavItem(label: '할일', icon: Icons.rule_folder_outlined, activeIcon: Icons.rule_folder_rounded, path: '/todos'),
    _NavItem(label: '마이', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).matchedLocation;
    final title = _resolveTitle(current);

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

  String _resolveTitle(String current) {
    if (current == '/curriculums') return '학습';
    if (current == '/search' || current.startsWith('/search/')) return '홈';
    return _items.firstWhere(
      (item) => current == item.path || current.startsWith('${item.path}/'),
      orElse: () => _items.first,
    ).label;
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
                  const Text('Study Pilot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                ],
              ),
            ),
            IconButton(
              tooltip: '테마 전환',
              onPressed: toggleThemeMode,
              icon: Icon(
                themeModeNotifier.value == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
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

  String _resolvePath(String currentPath) {
    if (currentPath == '/curriculums') return '/guidelines';
    if (currentPath == '/search' || currentPath.startsWith('/search/')) return '/';
    return currentPath;
  }

  @override
  Widget build(BuildContext context) {
    final activePath = _resolvePath(currentPath);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: AppShell._items.map((item) {
            final active = activePath == item.path || activePath.startsWith('${item.path}/');
            return Expanded(
              child: InkWell(
                onTap: () => context.go(item.path),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF0050CB) : Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: active
                              ? const [
                                  BoxShadow(
                                    color: Color(0x330050CB),
                                    blurRadius: 15,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          active ? item.activeIcon : item.icon,
                          size: 24,
                          color: active ? Colors.white : const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                          color: active ? const Color(0xFF0050CB) : const Color(0xFF6B7280),
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
  final IconData activeIcon;
  final String path;
  const _NavItem({required this.label, required this.icon, required this.activeIcon, required this.path});
}
