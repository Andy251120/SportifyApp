import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/features/profile/data/profile_model.dart';

void main() {
  group('SportType', () {
    test('fromDb maps known values', () {
      expect(SportType.fromDb('tennis'), SportType.tennis);
      expect(SportType.fromDb('pickleball'), SportType.pickleball);
    });
    test('fromDb falls back to tennis on unknown', () {
      expect(SportType.fromDb('badminton'), SportType.tennis);
    });
    test('dbValue round-trips', () {
      for (final s in SportType.values) {
        expect(SportType.fromDb(s.dbValue), s);
      }
    });
  });

  group('SkillMatrix (thang 0–100)', () {
    test('maxValue là 100', () {
      expect(SkillMatrix.maxValue, 100);
    });

    test('toJson/fromJson round-trip, toJson ghi số nguyên', () {
      const m = SkillMatrix(
        spin: 72,
        power: 58,
        speed: 80,
        mental: 41,
        stamina: 64,
        technique: 95,
      );
      final json = m.toJson();
      expect(json['spin'], 72);
      expect(json['spin'], isA<int>());
      final back = SkillMatrix.fromJson(json);
      expect(back.speed, 80);
      expect(back.technique, 95);
    });

    test('fromJson clamps out-of-range and handles missing keys', () {
      final m = SkillMatrix.fromJson({'spin': 420, 'power': -3});
      expect(m.spin, 100);
      expect(m.power, 0);
      expect(m.speed, 0); // missing -> 0
    });

    test('withAxis updates only the target axis', () {
      const base = SkillMatrix.filled(50);
      final updated = base.withAxis('speed', 90);
      expect(updated.speed, 90);
      expect(updated.spin, 50);
      expect(updated.technique, 50);
    });

    test('withAxis clamps to 0..100', () {
      const base = SkillMatrix.filled(50);
      expect(base.withAxis('spin', 200).spin, 100);
      expect(base.withAxis('spin', -5).spin, 0);
    });

    test('axes: 6 trục đúng thứ tự + nhãn UI_SPEC', () {
      final axes = const SkillMatrix.zero().axes;
      expect(axes.map((a) => a.key).toList(),
          ['spin', 'power', 'speed', 'mental', 'stamina', 'technique']);
      expect(axes.map((a) => a.label).toList(),
          ['Xoáy bóng', 'Lực đánh', 'Tốc độ', 'Tinh thần', 'Thể lực', 'Kỹ thuật']);
    });

    test('overall là trung bình làm tròn', () {
      expect(const SkillMatrix.filled(50).overall, 50);
      expect(
        const SkillMatrix(
                spin: 60, power: 60, speed: 60, mental: 60, stamina: 60, technique: 63)
            .overall,
        61,
      );
    });
  });

  group('Profile.needsOnboarding', () {
    Profile make({String? name, List<SportStats> stats = const []}) => Profile(
          id: 'u1',
          fullName: name,
          stats: stats,
        );

    const oneStat = SportStats(
      id: 's1',
      profileId: 'u1',
      sport: SportType.tennis,
      rating: 0,
      skillMatrix: SkillMatrix.zero(),
      titles: [],
      matchesPlayed: 0,
    );

    test('true when no name', () {
      expect(make(name: null, stats: [oneStat]).needsOnboarding, isTrue);
      expect(make(name: '  ', stats: [oneStat]).needsOnboarding, isTrue);
    });
    test('true when no sport_stats', () {
      expect(make(name: 'Mạnh', stats: const []).needsOnboarding, isTrue);
    });
    test('false when name + at least one sport', () {
      expect(make(name: 'Mạnh', stats: [oneStat]).needsOnboarding, isFalse);
    });
  });

  group('Profile.copyWith', () {
    final base = Profile(
      id: 'u1',
      fullName: 'Mạnh',
      avatarUrl: 'a.png',
      coverUrl: 'c.png',
      locationDistrict: 'Hải Châu',
      trustScore: 80,
      currentMode: SportType.tennis,
      isVerified: true,
      updatedAt: DateTime(2026, 1, 1),
      stats: const [
        SportStats(
          id: 's1',
          profileId: 'u1',
          sport: SportType.tennis,
          rating: 0,
          skillMatrix: SkillMatrix.zero(),
          titles: [],
          matchesPlayed: 0,
        ),
      ],
    );

    test('không truyền gì → giữ nguyên mọi field', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.fullName, base.fullName);
      expect(copy.avatarUrl, base.avatarUrl);
      expect(copy.coverUrl, base.coverUrl);
      expect(copy.locationDistrict, base.locationDistrict);
      expect(copy.trustScore, base.trustScore);
      expect(copy.currentMode, base.currentMode);
      expect(copy.isVerified, base.isVerified);
      expect(copy.updatedAt, base.updatedAt);
      expect(copy.stats, base.stats);
    });

    test('đổi đúng field truyền vào, phần còn lại giữ nguyên', () {
      final copy = base.copyWith(currentMode: SportType.pickleball);
      expect(copy.currentMode, SportType.pickleball);
      expect(copy.fullName, 'Mạnh');
      expect(copy.trustScore, 80);
      expect(copy.stats, base.stats);
    });

    test('set field nullable về null tường minh', () {
      final copy = base.copyWith(avatarUrl: null, updatedAt: null);
      expect(copy.avatarUrl, isNull);
      expect(copy.updatedAt, isNull);
      // field nullable không truyền vẫn giữ giá trị cũ
      expect(copy.coverUrl, 'c.png');
      expect(copy.fullName, 'Mạnh');
    });
  });

  group('Profile.fromJson', () {
    test('parses nested sport_stats', () {
      final p = Profile.fromJson({
        'id': 'u1',
        'full_name': 'Mạnh',
        'location_district': 'Hải Châu',
        'trust_score': 100,
        'current_mode': 'pickleball',
        'is_verified': false,
        'sport_stats': [
          {
            'id': 's1',
            'profile_id': 'u1',
            'sport': 'pickleball',
            'rating': 0,
            'skill_matrix': {'spin': 30, 'power': 45},
            'titles': [],
            'matches_played': 0,
          }
        ],
      });
      expect(p.fullName, 'Mạnh');
      expect(p.currentMode, SportType.pickleball);
      expect(p.stats, hasLength(1));
      expect(p.statsFor(SportType.pickleball)!.skillMatrix.power, 45);
      expect(p.statsFor(SportType.tennis), isNull);
      expect(p.needsOnboarding, isFalse);
    });
  });
}
