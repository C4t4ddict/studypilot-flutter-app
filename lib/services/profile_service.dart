import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileDto {
  final String id;
  final String email;
  final String nickname;
  final String createdAt;
  final String jobGoal;
  final String studyStyle;
  final List<String> interests;

  ProfileDto copyWith({
    String? nickname,
    String? jobGoal,
    String? studyStyle,
    List<String>? interests,
  }) {
    return ProfileDto(
      id: id,
      email: email,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt,
      jobGoal: jobGoal ?? this.jobGoal,
      studyStyle: studyStyle ?? this.studyStyle,
      interests: interests ?? this.interests,
    );
  }

  ProfileDto({
    required this.id,
    required this.email,
    required this.nickname,
    required this.createdAt,
    required this.jobGoal,
    required this.studyStyle,
    required this.interests,
  });
}

class ProfileExtraDto {
  final String jobGoal;
  final String studyStyle;
  final List<String> interests;

  const ProfileExtraDto({
    required this.jobGoal,
    required this.studyStyle,
    required this.interests,
  });

  Map<String, dynamic> toJson() => {
    'jobGoal': jobGoal,
    'studyStyle': studyStyle,
    'interests': interests,
  };

  factory ProfileExtraDto.fromJson(Map<String, dynamic> json) {
    return ProfileExtraDto(
      jobGoal: (json['jobGoal'] as String?) ?? '',
      studyStyle: (json['studyStyle'] as String?) ?? '',
      interests: ((json['interests'] as List?) ?? const []).map((e) => '$e').toList(),
    );
  }
}

class ProfileService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const _extraPrefix = 'profile_extra_';

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

    await _client.from('profiles').update({'nickname': trimmed}).eq('id', user.id);
  }

  static Future<void> updateProfileExtras({
    required String jobGoal,
    required String studyStyle,
    required List<String> interests,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final prefs = await SharedPreferences.getInstance();
    final payload = ProfileExtraDto(
      jobGoal: jobGoal.trim(),
      studyStyle: studyStyle.trim(),
      interests: interests.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    );
    await prefs.setString('$_extraPrefix${user.id}', jsonEncode(payload.toJson()));
  }

  static Future<ProfileExtraDto> _fetchProfileExtras(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_extraPrefix$userId');
    if (raw == null || raw.isEmpty) {
      return const ProfileExtraDto(jobGoal: '', studyStyle: '', interests: []);
    }
    return ProfileExtraDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
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
    final extra = await _fetchProfileExtras(user.id);

    return ProfileDto(
      id: data['id'] as String,
      email: (data['email'] as String?) ?? user.email ?? '-',
      nickname: (data['nickname'] as String?) ?? 'anonymous',
      createdAt: (data['created_at'] as String?) ?? '-',
      jobGoal: extra.jobGoal,
      studyStyle: extra.studyStyle,
      interests: extra.interests,
    );
  }
}
