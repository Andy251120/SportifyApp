/// Trạng thái lời mời ghép kèo — khớp CHECK constraint `match_requests.status`
/// (`open` | `matched` | `cancelled`).
enum MatchRequestStatus {
  open,
  matched,
  cancelled;

  static MatchRequestStatus fromDb(String value) => switch (value) {
        'matched' => MatchRequestStatus.matched,
        'cancelled' => MatchRequestStatus.cancelled,
        _ => MatchRequestStatus.open,
      };

  String get dbValue => name;
}

/// Trạng thái đăng ký tham gia kèo — khớp CHECK `match_request_responses.status`
/// (`pending` | `accepted` | `declined`).
enum ResponseStatus {
  pending,
  accepted,
  declined;

  static ResponseStatus fromDb(String value) => switch (value) {
        'accepted' => ResponseStatus.accepted,
        'declined' => ResponseStatus.declined,
        _ => ResponseStatus.pending,
      };

  String get dbValue => name;
}

/// Projection của `profiles` cho card ghép kèo (creator / responder).
///
/// Type cục bộ của feature `matchmaking` — chấp nhận trùng nhẹ với `ProfileLite`
/// của feature `matches`; không refactor gộp ở Phase 3.
class RequestProfile {
  const RequestProfile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.district,
  });

  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? district;

  String get displayName =>
      (fullName == null || fullName!.trim().isEmpty) ? 'Người chơi' : fullName!;

  factory RequestProfile.fromJson(Map<String, dynamic> json) => RequestProfile(
        id: json['id'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        district: json['location_district'] as String?,
      );
}

/// Map với row `match_request_responses` (kèm nested `responder:profiles`).
class MatchRequestResponse {
  const MatchRequestResponse({
    required this.id,
    required this.matchRequestId,
    required this.responderId,
    required this.status,
    required this.createdAt,
    this.responder,
  });

  final String id;
  final String matchRequestId;
  final String responderId;
  final ResponseStatus status;
  final DateTime createdAt;
  final RequestProfile? responder;

  factory MatchRequestResponse.fromJson(Map<String, dynamic> json) =>
      MatchRequestResponse(
        id: json['id'] as String,
        matchRequestId: json['match_request_id'] as String,
        responderId: json['responder_id'] as String,
        status: ResponseStatus.fromDb(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        responder: json['responder'] is Map<String, dynamic>
            ? RequestProfile.fromJson(json['responder'] as Map<String, dynamic>)
            : null,
      );
}

/// Map với row `match_requests` + nested creator/responses (nested select).
class MatchRequest {
  const MatchRequest({
    required this.id,
    required this.sport,
    required this.creatorId,
    required this.status,
    this.preferredDate,
    this.note,
    required this.createdAt,
    this.creator,
    this.creatorRating,
    this.creatorMatchesPlayed,
    this.responses = const [],
  });

  final String id;
  final String sport; // 'tennis' | 'pickleball'
  final String creatorId;
  final MatchRequestStatus status;
  final DateTime? preferredDate;
  final String? note;
  final DateTime createdAt;
  final RequestProfile? creator;

  /// Điểm Elo của creator ở môn của kèo. `null` = chưa có điểm
  /// (`sport_stats.rating` là `0`/`null`, hoặc creator chưa mở môn này).
  final double? creatorRating;
  final int? creatorMatchesPlayed;
  final List<MatchRequestResponse> responses;

  /// Response của chính tôi trong kèo này (nếu đã đăng ký).
  MatchRequestResponse? myResponse(String myId) {
    for (final r in responses) {
      if (r.responderId == myId) return r;
    }
    return null;
  }

  /// Response đã được creator chấp nhận (nếu có).
  MatchRequestResponse? get acceptedResponse {
    for (final r in responses) {
      if (r.status == ResponseStatus.accepted) return r;
    }
    return null;
  }

  int get pendingCount =>
      responses.where((r) => r.status == ResponseStatus.pending).length;

  /// Trả về phần tử `sport_stats` khớp `sport` của kèo trong nested creator.
  static Map<String, dynamic>? _creatorStat(dynamic creator, String sport) {
    if (creator is! Map) return null;
    final stats = creator['sport_stats'];
    if (stats is! List) return null;
    for (final s in stats) {
      if (s is Map<String, dynamic> && s['sport'] == sport) return s;
    }
    return null;
  }

  factory MatchRequest.fromJson(Map<String, dynamic> json) {
    final sport = json['sport'] as String;
    final rawCreator = json['creator'];
    final stat = _creatorStat(rawCreator, sport);
    final rawRating = (stat?['rating'] as num?)?.toDouble();
    final rawResponses = json['match_request_responses'];
    return MatchRequest(
      id: json['id'] as String,
      sport: sport,
      creatorId: json['creator_id'] as String,
      status: MatchRequestStatus.fromDb(json['status'] as String),
      preferredDate: json['preferred_date'] != null
          ? DateTime.tryParse(json['preferred_date'] as String)
          : null,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      creator: rawCreator is Map<String, dynamic>
          ? RequestProfile.fromJson(rawCreator)
          : null,
      creatorRating: (rawRating == null || rawRating == 0) ? null : rawRating,
      creatorMatchesPlayed: (stat?['matches_played'] as num?)?.toInt(),
      responses: rawResponses is List
          ? rawResponses
              .whereType<Map<String, dynamic>>()
              .map(MatchRequestResponse.fromJson)
              .toList()
          : const [],
    );
  }
}

/// Kết quả RPC `get_matched_contact` — SĐT + thông tin gọn của đối phương,
/// chỉ khả dụng sau khi kèo `matched`.
class MatchedContact {
  const MatchedContact({
    required this.profileId,
    this.fullName,
    this.avatarUrl,
    this.phone,
  });

  final String profileId;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;

  factory MatchedContact.fromJson(Map<String, dynamic> json) => MatchedContact(
        profileId: json['profile_id'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        phone: json['phone'] as String?,
      );
}
