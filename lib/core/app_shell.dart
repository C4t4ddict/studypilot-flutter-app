import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const items = [
    _NavItem(label: '홈', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, path: '/'),
    _NavItem(label: '학습', icon: Icons.import_contacts_outlined, activeIcon: Icons.import_contacts_rounded, path: '/guidelines'),
    _NavItem(label: '할일', icon: Icons.rule_folder_outlined, activeIcon: Icons.rule_folder_rounded, path: '/todos'),
    _NavItem(label: '캘린더', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, path: '/calendar'),
    _NavItem(label: '마이페이지', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).matchedLocation;
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
            BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, -8)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: AppShell.items.map((item) {
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
                              ? const [BoxShadow(color: Color(0x330050CB), blurRadius: 15, offset: Offset(0, 4))]
                              : null,
                        ),
                        child: Icon(active ? item.activeIcon : item.icon, size: 24, color: active ? Colors.white : const Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        maxLines: 1,
                        style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w600, color: active ? const Color(0xFF0050CB) : const Color(0xFF6B7280)),
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
