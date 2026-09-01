import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_model.dart';

/// Lớp duy nhất được phép gọi Supabase cho `profiles`, `sport_stats` và
/// storage bucket `avatars`.
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  static const _profileColumns =
      'id, full_name, avatar_url, cover_url, location_district, '
      'trust_score, current_mode, is_verified, updated_at';

  String? get _uid => _client.auth.currentUser?.id;

  /// Lấy hồ sơ của user hiện tại kèm toàn bộ `sport_stats`.
  Future<Profile?> fetchMyProfile() async {
    final uid = _uid;
    if (uid == null) return null;

    final row = await _client
        .from('profiles')
        .select('$_profileColumns, sport_stats(*)')
        .eq('id', uid)
        .maybeSingle();

    if (row == null) return null;
    return Profile.fromJson(row);
  }

  /// Hoàn tất onboarding: điền tên/quận + tạo 1 row `sport_stats` cho mỗi môn.
  Future<void> completeOnboarding({
    required String fullName,
    required String district,
    required List<SportType> sports,
    required Map<SportType, SkillMatrix> ratings,
  }) async {
    final uid = _requireUid();

    await _client.from('profiles').update({
      'full_name': fullName.trim(),
      'location_district': district,
      'current_mode': sports.first.dbValue,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);

    await _client.from('sport_stats').insert([
      for (final s in sports)
        {
          'profile_id': uid,
          'sport': s.dbValue,
          'skill_matrix': (ratings[s] ?? const SkillMatrix.zero()).toJson(),
        },
    ]);
  }

  /// Mở thêm 1 môn ở màn Hồ sơ (tạo row sport_stats mới).
  Future<void> addSport(SportType sport, SkillMatrix matrix) async {
    final uid = _requireUid();
    await _client.from('sport_stats').insert({
      'profile_id': uid,
      'sport': sport.dbValue,
      'skill_matrix': matrix.toJson(),
    });
  }

  Future<void> updateSkillMatrix(SportType sport, SkillMatrix matrix) async {
    final uid = _requireUid();
    await _client
        .from('sport_stats')
        .update({'skill_matrix': matrix.toJson()})
        .eq('profile_id', uid)
        .eq('sport', sport.dbValue);
  }

  /// Tab môn đang xem (SCHEMA: `profiles.current_mode`).
  Future<void> setCurrentMode(SportType sport) async {
    final uid = _requireUid();
    await _client
        .from('profiles')
        .update({'current_mode': sport.dbValue}).eq('id', uid);
  }

  Future<void> updateBasics({String? fullName, String? district}) async {
    final uid = _requireUid();
    final patch = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (fullName != null) patch['full_name'] = fullName.trim();
    if (district != null) patch['location_district'] = district;
    await _client.from('profiles').update(patch).eq('id', uid);
  }

  /// Upload avatar vào `avatars/<uid>/...` (khớp RLS policy) và cập nhật
  /// `profiles.avatar_url`. Trả về URL public.
  Future<String> uploadAvatar(Uint8List bytes, String ext) async {
    final uid = _requireUid();
    final safeExt = ext.toLowerCase() == 'png' ? 'png' : 'jpg';
    final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$safeExt',
          ),
        );

    final url = _client.storage.from('avatars').getPublicUrl(path);
    await _client.from('profiles').update({
      'avatar_url': url,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);

    return url;
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Chưa đăng nhập — không thao tác được hồ sơ.');
    }
    return uid;
  }
}
