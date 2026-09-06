import 'package:supabase_flutter/supabase_flutter.dart';

import 'match_request_model.dart';

/// Lớp duy nhất được phép gọi Supabase cho feature `matchmaking`
/// (`match_requests`, `match_request_responses` + các RPC ghép kèo).
class MatchRequestRepository {
  MatchRequestRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  /// Nested select đầy đủ cho card + màn chi tiết kèo.
  static const _columns =
      '*, creator:profiles!creator_id(id, full_name, avatar_url, location_district, '
      'sport_stats(sport, rating, matches_played)), '
      'match_request_responses(*, responder:profiles(id, full_name, avatar_url, location_district))';

  /// Kèo `open` của người khác ở [sport] — cho danh sách "Kèo đang mở".
  Future<List<MatchRequest>> fetchOpenRequests(String sport) async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _client
        .from('match_requests')
        .select(_columns)
        .eq('sport', sport)
        .eq('status', 'open')
        .neq('creator_id', uid)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(MatchRequest.fromJson)
        .toList();
  }

  /// Kèo do tôi tạo (mọi trạng thái trừ `cancelled`).
  Future<List<MatchRequest>> fetchMyRequests() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _client
        .from('match_requests')
        .select(_columns)
        .eq('creator_id', uid)
        .neq('status', 'cancelled')
        .order('created_at', ascending: false);
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(MatchRequest.fromJson)
        .toList();
  }

  /// Chi tiết 1 kèo.
  Future<MatchRequest> fetchRequest(String id) async {
    final row = await _client
        .from('match_requests')
        .select(_columns)
        .eq('id', id)
        .single();
    return MatchRequest.fromJson(row);
  }

  /// Tạo lời mời ghép kèo. Beta KHÔNG dùng `min_rating`/`max_rating`/`district`.
  /// Trả về id kèo vừa tạo.
  Future<String> createRequest({
    required String sport,
    DateTime? preferredDate,
    String? note,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Chưa đăng nhập');
    final payload = <String, dynamic>{
      'sport': sport,
      'creator_id': uid,
      if (preferredDate != null)
        'preferred_date': preferredDate.toIso8601String().split('T').first,
      if (note != null) 'note': note,
    };
    final row =
        await _client.from('match_requests').insert(payload).select('id').single();
    return row['id'] as String;
  }

  Future<void> cancelRequest(String id) async {
    await _client.from('match_requests').update({'status': 'cancelled'}).eq('id', id);
  }

  /// Đăng ký tham gia 1 kèo (`match_request_responses` mặc định `pending`).
  Future<void> respond(String requestId) async {
    final uid = _uid;
    if (uid == null) throw StateError('Chưa đăng nhập');
    await _client.from('match_request_responses').insert({
      'match_request_id': requestId,
      'responder_id': uid,
    });
  }

  /// Rút đăng ký — responder tự set response về `declined`
  /// (RLS + trigger UPDATE cho phép responder/creator set `declined`).
  Future<void> withdrawResponse(String responseId) async {
    await _client
        .from('match_request_responses')
        .update({'status': 'declined'}).eq('id', responseId);
  }

  /// Creator chấp nhận 1 response qua RPC atomic. Trả về `match_request_id`.
  Future<String> acceptResponse(String responseId) async {
    final result = await _client.rpc(
      'accept_match_request_response',
      params: {'p_response_id': responseId},
    );
    return result as String;
  }

  /// SĐT + thông tin đối phương sau khi kèo `matched`. `null` nếu chưa được phép.
  Future<MatchedContact?> matchedContact(String requestId) async {
    final result = await _client.rpc(
      'get_matched_contact',
      params: {'p_match_request_id': requestId},
    );
    final list = (result as List?) ?? const [];
    if (list.isEmpty) return null;
    final first = list.first;
    if (first is! Map) return null;
    return MatchedContact.fromJson(Map<String, dynamic>.from(first));
  }
}
