import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileDto {
  final String id;
  final String email;
  final String nickname;
  final String createdAt;

  ProfileDto copyWith({String? nickname}) {
    return ProfileDto(
      id: id,
      email: email,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt,
    );
  }

  ProfileDto({
    required this.id,
    required this.email,
    required this.nickname,
    required this.createdAt,
  });
}

class ProfileService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> upsertMyProfileIfNeeded() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email ?? '',
      'nickname': (user.userMetadata?['name'] as String?) ??
          (user.email?.split('@').first ?? 'user'),
    });
  }

  static Future<void> updateMyNickname(String nickname) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      throw Exception('닉네임은 비어 있을 수 없습니다.');
    }

    await _client
        .from('profiles')
        .update({'nickname': trimmed}).eq('id', user.id);
  }

  static Future<ProfileDto?> fetchMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select('id,email,nickname,created_at')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;

    return ProfileDto(
      id: data['id'] as String,
      email: (data['email'] as String?) ?? user.email ?? '-',
      nickname: (data['nickname'] as String?) ?? 'anonymous',
      createdAt: (data['created_at'] as String?) ?? '-',
    );
  }
}
