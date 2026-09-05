import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/features/matches/data/match_model.dart';

MatchSummary _match({
  required List<SetScore> score,
  MatchStatus status = MatchStatus.pendingConfirmation,
  String reportedBy = 'reporter',
  List<MatchParticipant> participants = const [],
}) {
  return MatchSummary(
    id: 'm1',
    sport: 'tennis',
    matchType: MatchType.singles,
    score: score,
    status: status,
    reportedBy: reportedBy,
    playedAt: DateTime(2026, 1, 1),
    reportedAt: DateTime(2026, 1, 1),
    autoConfirmed: false,
    participants: participants,
  );
}

const _me = MatchParticipant(profileId: 'me', side: 'a');
const _foe = MatchParticipant(profileId: 'foe', side: 'b');

void main() {
  group('MatchType / MatchStatus mapping', () {
    test('round-trips', () {
      expect(MatchType.fromDb('doubles'), MatchType.doubles);
      expect(MatchType.fromDb('singles').dbValue, 'singles');
      expect(MatchStatus.fromDb('pending_confirmation'), MatchStatus.pendingConfirmation);
      expect(MatchStatus.confirmed.dbValue, 'confirmed');
      expect(MatchStatus.fromDb('???'), MatchStatus.pendingConfirmation);
    });
  });

  group('SetScore', () {
    test('fromJson/toJson + winner', () {
      final s = SetScore.fromJson({'a': 6, 'b': 4});
      expect(s.toJson(), {'a': 6, 'b': 4});
      expect(s.winner, 1);
      expect(const SetScore(a: 3, b: 6).winner, -1);
      expect(const SetScore(a: 6, b: 6).winner, 0);
    });
  });

  group('MatchSummary.winnerSide', () {
    test('bên a thắng 2-0', () {
      final m = _match(score: const [SetScore(a: 6, b: 4), SetScore(a: 6, b: 3)]);
      expect(m.winnerSide, 'a');
    });
    test('bên b thắng 2-1', () {
      final m = _match(score: const [
        SetScore(a: 6, b: 4),
        SetScore(a: 3, b: 6),
        SetScore(a: 5, b: 7),
      ]);
      expect(m.winnerSide, 'b');
    });
    test('hoà set → null', () {
      final m = _match(score: const [SetScore(a: 6, b: 4), SetScore(a: 4, b: 6)]);
      expect(m.winnerSide, isNull);
    });
    test('score rỗng → null', () {
      expect(_match(score: const []).winnerSide, isNull);
    });
  });

  group('didIWin', () {
    test('tôi ở bên thắng', () {
      final m = _match(
        score: const [SetScore(a: 6, b: 1), SetScore(a: 6, b: 2)],
        participants: const [_me, _foe],
      );
      expect(m.didIWin('me'), isTrue);
      expect(m.didIWin('foe'), isFalse);
    });
  });

  group('canConfirm', () {
    test('true khi pending + tôi tham gia + không phải người báo cáo', () {
      final m = _match(
        score: const [SetScore(a: 6, b: 0)],
        reportedBy: 'foe',
        participants: const [_me, _foe],
      );
      expect(m.canConfirm('me'), isTrue);
    });
    test('false khi tôi là người báo cáo', () {
      final m = _match(
        score: const [SetScore(a: 6, b: 0)],
        reportedBy: 'me',
        participants: const [_me, _foe],
      );
      expect(m.canConfirm('me'), isFalse);
    });
    test('false khi đã confirmed', () {
      final m = _match(
        score: const [SetScore(a: 6, b: 0)],
        status: MatchStatus.confirmed,
        reportedBy: 'foe',
        participants: const [_me, _foe],
      );
      expect(m.canConfirm('me'), isFalse);
    });
    test('false khi tôi không tham gia trận', () {
      final m = _match(
        score: const [SetScore(a: 6, b: 0)],
        reportedBy: 'foe',
        participants: const [_foe],
      );
      expect(m.canConfirm('me'), isFalse);
    });
  });

  group('MatchSummary.fromJson', () {
    test('parse nested match_participants + profile', () {
      final m = MatchSummary.fromJson({
        'id': 'm1',
        'sport': 'pickleball',
        'match_type': 'doubles',
        'score': [
          {'a': 11, 'b': 9},
          {'a': 11, 'b': 7}
        ],
        'status': 'confirmed',
        'reported_by': 'u1',
        'confirmed_by': 'u2',
        'played_at': '2026-01-01T10:00:00Z',
        'reported_at': '2026-01-01T10:05:00Z',
        'auto_confirmed': false,
        'match_participants': [
          {
            'profile_id': 'u1',
            'side': 'a',
            'rating_before': 1000,
            'rating_after': 1016,
            'profile': {'id': 'u1', 'full_name': 'An', 'avatar_url': null},
          },
          {'profile_id': 'u2', 'side': 'b', 'rating_before': 1000, 'rating_after': 984},
        ],
      });
      expect(m.sport, 'pickleball');
      expect(m.matchType, MatchType.doubles);
      expect(m.status, MatchStatus.confirmed);
      expect(m.score, hasLength(2));
      expect(m.winnerSide, 'a');
      expect(m.participants, hasLength(2));
      expect(m.me('u1')!.profile!.displayName, 'An');
      expect(m.me('u1')!.ratingAfter, 1016);
      expect(m.sideParticipants('b').single.profileId, 'u2');
    });
  });
}
