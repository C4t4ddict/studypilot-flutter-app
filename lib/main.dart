import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'core/theme_controller.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  final hasRealSupabase = url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('YOUR_PROJECT') &&
      !anonKey.contains('YOUR_ANON_KEY');

  await AuthService.configureDemoMode(!hasRealSupabase);
  await AuthService.restoreDemoSessionIfNeeded();

  if (hasRealSupabase) {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  runApp(const GuiculumApp());
}

class GuiculumApp extends StatelessWidget {
  const GuiculumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        final authState = snapshot.data;
        if (!AuthService.isDemoMode && authState?.event == AuthChangeEvent.signedIn) {
          ProfileService.upsertMyProfileIfNeeded();
        }

        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, mode, _) {
            return MaterialApp.router(
              title: 'Study Pilot',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: mode,
              routerConfig: appRouter,
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
