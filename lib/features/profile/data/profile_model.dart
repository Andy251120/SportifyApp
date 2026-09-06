/// Môn thể thao. Map 1-1 với enum `sport_type` trong SCHEMA.md (`tennis` | `pickleball`).
enum SportType {
  tennis,
  pickleball;

  static SportType fromDb(String value) => SportType.values.firstWhere(
        (s) => s.name == value,
        orElse: () => SportType.tennis,
      );

  String get dbValue => name;

  String get label => switch (this) {
        SportType.tennis => 'Tennis',
        SportType.pickleball => 'Pickleball',
      };
}

/// 6 trục kỹ năng cá nhân hoá cho radar "Show-off". Thang 0–100 (số nguyên).
/// Map với cột jsonb `sport_stats.skill_matrix` — client tự sửa được.
class SkillMatrix {
  const SkillMatrix({
    required this.spin,
    required this.power,
    required this.speed,
    required this.mental,
    required this.stamina,
    required this.technique,
  });

  final double spin;
  final double power;
  final double speed;
  final double mental;
  final double stamina;
  final double technique;

  static const double maxValue = 100;

  const SkillMatrix.zero()
      : spin = 0,
        power = 0,
        speed = 0,
        mental = 0,
        stamina = 0,
        technique = 0;

  const SkillMatrix.filled(double v)
      : spin = v,
        power = v,
        speed = v,
        mental = v,
        stamina = v,
        technique = v;

  factory SkillMatrix.fromJson(Map<String, dynamic> json) {
    double read(String key) {
      final raw = json[key];
      if (raw is num) return raw.toDouble().clamp(0, maxValue);
      return 0;
    }

    return SkillMatrix(
      spin: read('spin'),
      power: read('power'),
      speed: read('speed'),
      mental: read('mental'),
      stamina: read('stamina'),
      technique: read('technique'),
    );
  }

  Map<String, dynamic> toJson() => {
        'spin': spin.round(),
        'power': power.round(),
        'speed': speed.round(),
        'mental': mental.round(),
        'stamina': stamina.round(),
        'technique': technique.round(),
      };

  /// Dùng để dựng radar chart + slider tự chấm. Thứ tự + nhãn theo UI_SPEC.md.
  List<SkillAxis> get axes => [
        SkillAxis('spin', 'Xoáy bóng', spin),
        SkillAxis('power', 'Lực đánh', power),
        SkillAxis('speed', 'Tốc độ', speed),
        SkillAxis('mental', 'Tinh thần', mental),
        SkillAxis('stamina', 'Thể lực', stamina),
        SkillAxis('technique', 'Kỹ thuật', technique),
      ];

  SkillMatrix withAxis(String key, double value) {
    final v = value.clamp(0, maxValue).toDouble();
    return SkillMatrix(
      spin: key == 'spin' ? v : spin,
      power: key == 'power' ? v : power,
      speed: key == 'speed' ? v : speed,
      mental: key == 'mental' ? v : mental,
      stamina: key == 'stamina' ? v : stamina,
      technique: key == 'technique' ? v : technique,
    );
  }

  /// Điểm trung bình 6 trục (0–100), làm tròn.
  int get overall {
    final total = spin + power + speed + mental + stamina + technique;
    return (total / 6).round();
  }
}

class SkillAxis {
  const SkillAxis(this.key, this.label, this.value);
  final String key;
  final String label;
  final double value;
}

/// Map với row `sport_stats`.
class SportStats {
  const SportStats({
    required this.id,
    required this.profileId,
    required this.sport,
    required this.rating,
    required this.skillMatrix,
    required this.titles,
    required this.matchesPlayed,
  });

  final String id;
  final String profileId;
  final SportType sport;

  /// Điểm Elo — client KHÔNG sửa được (chỉ rating engine hoặc service_role).
  /// `0` = chưa có điểm; rating engine coi `0` là baseline 1000 khi tính (Phase 2).
  final double rating;
  final SkillMatrix skillMatrix;
  final List<String> titles;
  final int matchesPlayed;

  bool get hasRating => rating > 0 && matchesPlayed > 0;

  factory SportStats.fromJson(Map<String, dynamic> json) {
    final matrix = json['skill_matrix'];
    return SportStats(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      sport: SportType.fromDb(json['sport'] as String),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      skillMatrix: matrix is Map<String, dynamic>
          ? SkillMatrix.fromJson(matrix)
          : const SkillMatrix.zero(),
      titles: (json['titles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      matchesPlayed: (json['matches_played'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Map với row `profiles` + danh sách `sport_stats` kèm theo (nested select).
class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.coverUrl,
    this.locationDistrict,
    this.trustScore = 100,
    this.currentMode = SportType.tennis,
    this.isVerified = false,
    this.updatedAt,
    this.stats = const [],
  });

  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? coverUrl;
  final String? locationDistrict;
  final int trustScore;
  final SportType currentMode;
  final bool isVerified;
  final DateTime? updatedAt;
  final List<SportStats> stats;

  /// User cần onboard nếu chưa có tên hoặc chưa mở môn nào.
  bool get needsOnboarding =>
      (fullName == null || fullName!.trim().isEmpty) || stats.isEmpty;

  SportStats? statsFor(SportType sport) {
    for (final s in stats) {
      if (s.sport == sport) return s;
    }
    return null;
  }

  List<SportType> get playedSports =>
      stats.map((s) => s.sport).toSet().toList();

  /// 2 ký tự đầu của tên cho avatar fallback (UI_SPEC).
  String get initials {
    final name = fullName?.trim() ?? '';
    if (name.isEmpty) return '🎾';
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Sao chép, đổi các field truyền vào. Field nullable dùng sentinel để cho
  /// phép set về `null` tường minh (giống `LoginState.copyWith`).
  Profile copyWith({
    String? id,
    Object? fullName = _sentinel,
    Object? avatarUrl = _sentinel,
    Object? coverUrl = _sentinel,
    Object? locationDistrict = _sentinel,
    int? trustScore,
    SportType? currentMode,
    bool? isVerified,
    Object? updatedAt = _sentinel,
    List<SportStats>? stats,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: identical(fullName, _sentinel) ? this.fullName : fullName as String?,
      avatarUrl: identical(avatarUrl, _sentinel) ? this.avatarUrl : avatarUrl as String?,
      coverUrl: identical(coverUrl, _sentinel) ? this.coverUrl : coverUrl as String?,
      locationDistrict: identical(locationDistrict, _sentinel)
          ? this.locationDistrict
          : locationDistrict as String?,
      trustScore: trustScore ?? this.trustScore,
      currentMode: currentMode ?? this.currentMode,
      isVerified: isVerified ?? this.isVerified,
      updatedAt: identical(updatedAt, _sentinel) ? this.updatedAt : updatedAt as DateTime?,
      stats: stats ?? this.stats,
    );
  }

  static const _sentinel = Object();

  factory Profile.fromJson(Map<String, dynamic> json) {
    final rawStats = json['sport_stats'];
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      locationDistrict: json['location_district'] as String?,
      trustScore: (json['trust_score'] as num?)?.toInt() ?? 100,
      currentMode: SportType.fromDb((json['current_mode'] as String?) ?? 'tennis'),
      isVerified: (json['is_verified'] as bool?) ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      stats: rawStats is List
          ? rawStats
              .whereType<Map<String, dynamic>>()
              .map(SportStats.fromJson)
              .toList()
          : const [],
    );
  }
}
