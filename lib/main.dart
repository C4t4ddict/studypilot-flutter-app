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

  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
    runApp(const MissingEnvApp());
    return;
  }

  await Supabase.initialize(url: url, anonKey: anonKey);
  runApp(const StudypilotApp());
}

class StudypilotApp extends StatelessWidget {
  const StudypilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        final authState = snapshot.data;
        if (authState?.event == AuthChangeEvent.signedIn) {
          // 최초 로그인 시 프로필 자동 upsert
          ProfileService.upsertMyProfileIfNeeded();
        }

        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, mode, _) {
            return MaterialApp.router(
              title: 'StudyPilot',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: mode,
              routerConfig: appRouter,
            );
          },
        );
      },
    );
  }
}

class MissingEnvApp extends StatelessWidget {
  const MissingEnvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Missing SUPABASE env.\nCopy .env.example -> .env and fill values.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
