import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;

class CalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [gcal.CalendarApi.calendarReadonlyScope],
    clientId: (dotenv.env['GOOGLE_CLIENT_ID'] ?? '').isEmpty
        ? null
        : dotenv.env['GOOGLE_CLIENT_ID'],
    serverClientId: (dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '').isEmpty
        ? null
        : dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
  );

  static Future<void> connectGoogleCalendar() async {
    final account =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google 로그인에 실패했습니다.');
    }
  }

  static Future<List<gcal.Event>> listUpcomingEvents({int max = 10}) async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw Exception('Google 인증 클라이언트가 없습니다. 다시 로그인해주세요.');
    }
    final api = gcal.CalendarApi(client);
    final now = DateTime.now().toUtc();
    final events = await api.events.list(
      'primary',
      timeMin: now,
      maxResults: max,
      singleEvents: true,
      orderBy: 'startTime',
    );
    return events.items ?? [];
  }

  static Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }
}
