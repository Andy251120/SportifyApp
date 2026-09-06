import 'package:supabase_flutter/supabase_flutter.dart';

import 'availability_model.dart';

/// Lớp duy nhất được phép gọi Supabase cho bảng `availability`.
class AvailabilityRepository {
  AvailabilityRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  /// `'HH:mm'` (client) → `'HH:mm:00'` (Postgres `time`).
  static String toDbTime(String hhmm) => '$hhmm:00';

  /// Các khung giờ rảnh của tôi.
  Future<List<AvailabilitySlot>> fetchMyAvailability() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _client
        .from('availability')
        .select()
        .eq('profile_id', uid)
        .order('day_of_week')
        .order('start_time');
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(AvailabilitySlot.fromJson)
        .toList();
  }

  /// Thêm 1 khung giờ. [start]/[end] dạng `'HH:mm'` → lưu `'HH:mm:00'`.
  Future<void> addSlot({
    required String sport,
    required int dayOfWeek,
    required String start,
    required String end,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Chưa đăng nhập');
    await _client.from('availability').insert({
      'profile_id': uid,
      'sport': sport,
      'day_of_week': dayOfWeek,
      'start_time': toDbTime(start),
      'end_time': toDbTime(end),
    });
  }

  Future<void> deleteSlot(String id) async {
    await _client.from('availability').delete().eq('id', id);
  }

  /// Khung giờ rảnh của 1 user cụ thể ở [sport] — cho màn chi tiết kèo.
  Future<List<AvailabilitySlot>> fetchAvailabilityFor(
      String profileId, String sport) async {
    final rows = await _client
        .from('availability')
        .select()
        .eq('profile_id', profileId)
        .eq('sport', sport)
        .order('day_of_week');
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(AvailabilitySlot.fromJson)
        .toList();
  }
}
