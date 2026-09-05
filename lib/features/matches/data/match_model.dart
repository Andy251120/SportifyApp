/// Loại trận: đơn (1 người/bên) hoặc đôi (2 người/bên).
enum MatchType {
  singles,
  doubles;

  static MatchType fromDb(String value) =>
      MatchType.values.firstWhere((t) => t.dbValue == value, orElse: () => MatchType.singles);

  String get dbValue => name;
  String get label => this == MatchType.singles ? 'Đơn' : 'Đôi';
}

/// Trạng thái trận — khớp CHECK constraint của `matches.status`.
enum MatchStatus {
  pendingConfirmation,
  confirmed,
  disputed,
  cancelled;

  static MatchStatus fromDb(String value) => switch (value) {
        'confirmed' => MatchStatus.confirmed,
        'disputed' => MatchStatus.disputed,
        'cancelled' => MatchStatus.cancelled,
        _ => MatchStatus.pendingConfirmation,
      };

  String get dbValue => switch (this) {
        MatchStatus.pendingConfirmation => 'pending_confirmation',
        MatchStatus.confirmed => 'confirmed',
        MatchStatus.disputed => 'disputed',
        MatchStatus.cancelled => 'cancelled',
      };
}

/// Tỷ số 1 set, khớp `matches.score` jsonb: `[{"a":6,"b":4}, ...]`.
class SetScore {
  const SetScore({required this.a, required this.b});

  final int a;
  final int b;

  factory SetScore.fromJson(Map<String, dynamic> json) => SetScore(
        a: (json['a'] as num?)?.toInt() ?? 0,
        b: (json['b'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'a': a, 'b': b};

  /// 1 nếu bên a thắng set này, -1 nếu bên b thắng, 0 nếu hoà (không nên xảy ra).
  int get winner => a == b ? 0 : (a > b ? 1 : -1);
}

/// Thông tin gọn của 1 user — dùng để tìm đối thủ/đồng đội và hiển thị participant.
class ProfileLite {
  const ProfileLite({required this.id, this.fullName, this.avatarUrl});

  final String id;
  final String? fullName;
  final String? avatarUrl;

  String get displayName => (fullName == null || fullName!.trim().isEmpty) ? 'Người chơi' : fullName!;

  factory ProfileLite.fromJson(Map<String, dynamic> json) => ProfileLite(
        id: json['id'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}

/// Map với row `match_participants` (kèm nested `profiles`).
class MatchParticipant {
  const MatchParticipant({
    required this.profileId,
    required this.side,
    this.ratingBefore,
    this.ratingAfter,
    this.profile,
  });

  final String profileId;
  final String side; // 'a' | 'b'
  final double? ratingBefore;
  final double? ratingAfter;
  final ProfileLite? profile;

  factory MatchParticipant.fromJson(Map<String, dynamic> json) => MatchParticipant(
        profileId: json['profile_id'] as String,
        side: json['side'] as String,
        ratingBefore: (json['rating_before'] as num?)?.toDouble(),
        ratingAfter: (json['rating_after'] as num?)?.toDouble(),
        profile: json['profile'] is Map<String, dynamic>
            ? ProfileLite.fromJson(json['profile'] as Map<String, dynamic>)
            : null,
      );
}

/// Map với row `matches` + participants đi kèm (nested select).
class MatchSummary {
  const MatchSummary({
    required this.id,
    required this.sport,
    required this.matchType,
    required this.score,
    required this.status,
    this.reportedBy,
    this.confirmedBy,
    required this.playedAt,
    required this.reportedAt,
    required this.autoConfirmed,
    this.participants = const [],
  });

  final String id;
  final String sport; // 'tennis' | 'pickleball'
  final MatchType matchType;
  final List<SetScore> score;
  final MatchStatus status;
  final String? reportedBy;
  final String? confirmedBy;
  final DateTime playedAt;
  final DateTime reportedAt;
  final bool autoConfirmed;
  final List<MatchParticipant> participants;

  factory MatchSummary.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'];
    return MatchSummary(
      id: json['id'] as String,
      sport: json['sport'] as String,
      matchType: MatchType.fromDb(json['match_type'] as String),
      score: rawScore is List
          ? rawScore.whereType<Map<String, dynamic>>().map(SetScore.fromJson).toList()
          : const [],
      status: MatchStatus.fromDb(json['status'] as String),
      reportedBy: json['reported_by'] as String?,
      confirmedBy: json['confirmed_by'] as String?,
      playedAt: DateTime.parse(json['played_at'] as String),
      reportedAt: DateTime.parse(json['reported_at'] as String),
      autoConfirmed: (json['auto_confirmed'] as bool?) ?? false,
      participants: json['match_participants'] is List
          ? (json['match_participants'] as List)
              .whereType<Map<String, dynamic>>()
              .map(MatchParticipant.fromJson)
              .toList()
          : const [],
    );
  }

  List<MatchParticipant> sideParticipants(String side) =>
      participants.where((p) => p.side == side).toList();

  MatchParticipant? me(String myId) {
    for (final p in participants) {
      if (p.profileId == myId) return p;
    }
    return null;
  }

  /// 'a' | 'b' | null (hoà — không nên xảy ra với luật tennis/pickleball).
  String? get winnerSide {
    var setsA = 0, setsB = 0;
    for (final s in score) {
      if (s.winner > 0) setsA++;
      if (s.winner < 0) setsB++;
    }
    if (setsA == setsB) return null;
    return setsA > setsB ? 'a' : 'b';
  }

  bool didIWin(String myId) {
    final mySide = me(myId)?.side;
    return mySide != null && mySide == winnerSide;
  }

  bool isReporter(String myId) => reportedBy == myId;

  /// Trận đang chờ xác nhận VÀ tôi là người có quyền xác nhận/từ chối
  /// (tôi tham gia trận nhưng không phải người báo cáo).
  bool canConfirm(String myId) =>
      status == MatchStatus.pendingConfirmation && !isReporter(myId) && me(myId) != null;
}
