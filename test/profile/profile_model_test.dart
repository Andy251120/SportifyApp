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

  group('SkillMatrix', () {
    test('toJson/fromJson round-trip', () {
      const m = SkillMatrix(
        spin: 7,
        power: 5,
        speed: 8,
        mental: 4,
        stamina: 6,
        technique: 9,
      );
      final back = SkillMatrix.fromJson(m.toJson());
      expect(back.spin, 7);
      expect(back.power, 5);
      expect(back.speed, 8);
      expect(back.mental, 4);
      expect(back.stamina, 6);
      expect(back.technique, 9);
    });

    test('fromJson clamps out-of-range and handles missing keys', () {
      final m = SkillMatrix.fromJson({'spin': 42, 'power': -3});
      expect(m.spin, 10);
      expect(m.power, 0);
      expect(m.speed, 0); // missing -> 0
    });

    test('withAxis updates only the target axis', () {
      const base = SkillMatrix.filled(5);
      final updated = base.withAxis('speed', 9);
      expect(updated.speed, 9);
      expect(updated.spin, 5);
      expect(updated.technique, 5);
    });

    test('axes has 6 entries in fixed order', () {
      final axes = const SkillMatrix.zero().axes;
      expect(axes.map((a) => a.key).toList(),
          ['spin', 'power', 'speed', 'mental', 'stamina', 'technique']);
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
            'skill_matrix': {'spin': 3, 'power': 4},
            'titles': [],
            'matches_played': 0,
          }
        ],
      });
      expect(p.fullName, 'Mạnh');
      expect(p.currentMode, SportType.pickleball);
      expect(p.stats, hasLength(1));
      expect(p.statsFor(SportType.pickleball)!.skillMatrix.power, 4);
      expect(p.statsFor(SportType.tennis), isNull);
      expect(p.needsOnboarding, isFalse);
    });
  });
}
