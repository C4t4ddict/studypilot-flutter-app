import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import '../features/home/home_page.dart';
import '../services/auth_service.dart';
import '../features/login/login_page.dart';
import '../features/login/signup_page.dart';
import '../features/search/search_page.dart';
import '../features/search/search_detail_page.dart';
import '../features/home/profile_page.dart';
import '../features/login/auth_callback_page.dart';
import '../features/planner/roadmap_page.dart';
import '../features/planner/curriculum_page.dart';
import '../features/planner/todo_page.dart';
import '../features/planner/calendar_page.dart';
import '../features/planner/review_page.dart';
import '../features/planner/templates_page.dart';
import '../features/planner/insights_page.dart';
import '../features/planner/productivity_page.dart';
import '../features/planner/gamification_page.dart';
import '../features/planner/ops_page.dart';
import '../features/planner/ai_assist_page.dart';
import '../features/planner/career_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = AuthService.currentUser() != null;
    final loc = state.matchedLocation;
    final isPublic = loc == '/' ||
        loc == '/login' ||
        loc == '/signup' ||
        loc == '/search' ||
        loc.startsWith('/search/') ||
        loc == '/auth/callback';

    if (!loggedIn && !isPublic) return '/login';
    if (loggedIn && (loc == '/login' || loc == '/signup')) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackPage()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
            path: '/search', builder: (context, state) => const SearchPage()),
        GoRoute(
          path: '/search/:id',
          builder: (context, state) =>
              SearchDetailPage(itemId: state.pathParameters['id'] ?? '-'),
        ),
        GoRoute(
            path: '/profile', builder: (context, state) => const ProfilePage()),
        GoRoute(
            path: '/roadmaps',
            builder: (context, state) => const RoadmapPage()),
        GoRoute(
            path: '/curriculums',
            builder: (context, state) => const CurriculumPage()),
        GoRoute(path: '/todos', builder: (context, state) => const TodoPage()),
        GoRoute(
            path: '/review', builder: (context, state) => const ReviewPage()),
        GoRoute(
            path: '/templates',
            builder: (context, state) => const TemplatesPage()),
        GoRoute(
            path: '/insights',
            builder: (context, state) => const InsightsPage()),
        GoRoute(
            path: '/productivity',
            builder: (context, state) => const ProductivityPage()),
        GoRoute(
            path: '/gamification',
            builder: (context, state) => const GamificationPage()),
        GoRoute(path: '/ops', builder: (context, state) => const OpsPage()),
        GoRoute(
            path: '/career', builder: (context, state) => const CareerPage()),
        GoRoute(
            path: '/ai-assist',
            builder: (context, state) => const AiAssistPage()),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => PlannerCalendarPage(
            embedded: true,
            initialView: state.uri.queryParameters['view'],
            initialFilter: state.uri.queryParameters['filter'],
            initialDate: state.uri.queryParameters['date'],
          ),
        ),
      ],
    ),
  ],
);
