import 'package:supabase_flutter/supabase_flutter.dart';

import 'match_model.dart';

/// Lớp duy nhất được phép gọi Supabase cho `matches`/`match_participants`
/// và tìm người chơi (bảng `profiles`).
class MatchRepository {
  MatchRepository(this._client);

  final SupabaseClient _client;

  static const _matchColumns = '*, match_participants(*, profile:profiles(id, full_name, avatar_url))';

  String? get _uid => _client.auth.currentUser?.id;

  /// Tạo trận qua RPC `create_match` (atomic matches + match_participants).
  /// Trả về id trận vừa tạo.
  Future<String> createMatch({
    required String sport,
    required MatchType matchType,
    required List<String> sideAIds,
    required List<String> sideBIds,
    required List<SetScore> score,
    DateTime? playedAt,
  }) async {
    final result = await _client.rpc('create_match', params: {
      'p_sport': sport,
      'p_match_type': matchType.dbValue,
      'p_side_a_ids': sideAIds,
      'p_side_b_ids': sideBIds,
      'p_score': score.map((s) => s.toJson()).toList(),
      'p_played_at': (playedAt ?? DateTime.now()).toUtc().toIso8601String(),
    });
    return result as String;
  }

  /// Mọi trận tôi là participant/official — RLS tự lọc, không cần .eq thêm.
  Future<List<MatchSummary>> fetchMyMatches() async {
    final rows = await _client
        .from('matches')
        .select(_matchColumns)
        .order('reported_at', ascending: false)
        .limit(50);
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(MatchSummary.fromJson)
        .toList();
  }

  Future<void> confirmMatch(String matchId) async {
    await _client.from('matches').update({'status': 'confirmed'}).eq('id', matchId);
  }

  Future<void> disputeMatch(String matchId) async {
    await _client.from('matches').update({'status': 'disputed'}).eq('id', matchId);
  }

  /// Tìm người chơi theo tên để chọn đối thủ/đồng đội — loại trừ chính mình.
  Future<List<ProfileLite>> searchPlayers(String query) async {
    if (query.trim().isEmpty) return [];
    final myId = _uid;
    final rows = await _client
        .from('profiles')
        .select('id, full_name, avatar_url')
        .ilike('full_name', '%${query.trim()}%')
        .limit(10);
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(ProfileLite.fromJson)
        .where((p) => p.id != myId)
        .toList();
  }
}
