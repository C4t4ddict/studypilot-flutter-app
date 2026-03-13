import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme_controller.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool expanded = false;

  Widget navItem(
      BuildContext context, IconData icon, String label, String path) {
    final current = GoRouterState.of(context).matchedLocation;
    final active = current == path;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : const Color(0xFF3E2D7A);
    return InkWell(
      onTap: () {
        context.go(path);
        setState(() => expanded = false);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active
              ? (dark ? Colors.white12 : const Color(0xFFDCD8F8))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active
                  ? (dark ? Colors.white38 : const Color(0xFFB8ADF3))
                  : (dark ? Colors.white10 : const Color(0xFFD7D9E8))),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(expanded ? Icons.menu_open : Icons.menu),
          onPressed: () => setState(() => expanded = !expanded),
        ),
        titleSpacing: 4,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18),
            const SizedBox(width: 8),
            const Text('GUICULUM'),
            const SizedBox(width: 18),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: TextField(
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Search anything...',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '라이트/다크 전환',
            onPressed: toggleThemeMode,
            icon: Icon(themeModeNotifier.value == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: widget.child),
          if (expanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => expanded = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            left: expanded ? 0 : -270,
            top: 0,
            bottom: 0,
            width: 260,
            child: Material(
              color: dark ? const Color(0xFF0A0B0F) : const Color(0xFFEEF0FA),
              elevation: 12,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Menu',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(() => expanded = false),
                            icon: const Icon(Icons.close),
                            tooltip: '닫기',
                          )
                        ],
                      ),
                      navItem(context, Icons.home_rounded, '홈', '/'),
                      const SizedBox(height: 10),
                      navItem(
                          context, Icons.rule_rounded, '가이드라인', '/guidelines'),
                      const SizedBox(height: 10),
                      navItem(context, Icons.event_note_rounded, '커리큘럼',
                          '/curriculums'),
                      const SizedBox(height: 10),
                      navItem(context, Icons.calendar_month_rounded, '캘린더',
                          '/calendar'),
                      const SizedBox(height: 10),
                      navItem(context, Icons.checklist_rounded, '투두', '/todos'),
                      const SizedBox(height: 10),
                      navItem(context, Icons.search_rounded, '검색', '/search'),
                      const Spacer(),
                      navItem(context, Icons.person_outline_rounded, '마이페이지',
                          '/profile'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
