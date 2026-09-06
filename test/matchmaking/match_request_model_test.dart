import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/features/matchmaking/data/availability_model.dart';
import 'package:sport_super_app/features/matchmaking/data/match_request_model.dart';

void main() {
  group('enum round-trip', () {
    test('MatchRequestStatus', () {
      for (final s in MatchRequestStatus.values) {
        expect(MatchRequestStatus.fromDb(s.dbValue), s);
      }
      expect(MatchRequestStatus.fromDb('open'), MatchRequestStatus.open);
      expect(MatchRequestStatus.fromDb('matched'), MatchRequestStatus.matched);
      expect(MatchRequestStatus.fromDb('cancelled'), MatchRequestStatus.cancelled);
      expect(MatchRequestStatus.fromDb('???'), MatchRequestStatus.open);
    });

    test('ResponseStatus', () {
      for (final s in ResponseStatus.values) {
        expect(ResponseStatus.fromDb(s.dbValue), s);
      }
      expect(ResponseStatus.fromDb('pending'), ResponseStatus.pending);
      expect(ResponseStatus.fromDb('accepted'), ResponseStatus.accepted);
      expect(ResponseStatus.fromDb('declined'), ResponseStatus.declined);
      expect(ResponseStatus.fromDb('???'), ResponseStatus.pending);
    });
  });

  Map<String, dynamic> requestJson({
    String sport = 'tennis',
    List<Map<String, dynamic>> responses = const [],
  }) {
    return {
      'id': 'req1',
      'sport': sport,
      'creator_id': 'creator1',
      'status': 'open',
      'preferred_date': '2026-09-20',
      'note': 'Sân Mỹ Khê 5h chiều nha',
      'created_at': '2026-09-06T10:00:00Z',
      'creator': {
        'id': 'creator1',
        'full_name': 'Anh Ba',
        'avatar_url': null,
        'location_district': 'Sơn Trà',
        'sport_stats': [
          {'sport': 'tennis', 'rating': 1180.5, 'matches_played': 12},
          {'sport': 'pickleball', 'rating': 0, 'matches_played': 0},
        ],
      },
      'match_request_responses': responses,
    };
  }

  Map<String, dynamic> responseJson({
    required String id,
    required String responderId,
    String status = 'pending',
  }) {
    return {
      'id': id,
      'match_request_id': 'req1',
      'responder_id': responderId,
      'status': status,
      'created_at': '2026-09-06T11:00:00Z',
      'responder': {
        'id': responderId,
        'full_name': 'Người $responderId',
        'avatar_url': null,
        'location_district': 'Hải Châu',
      },
    };
  }

  group('MatchRequest.fromJson', () {
    test('map field + creator + chọn sport_stats theo sport tennis', () {
      final r = MatchRequest.fromJson(requestJson());
      expect(r.id, 'req1');
      expect(r.sport, 'tennis');
      expect(r.status, MatchRequestStatus.open);
      expect(r.preferredDate, DateTime.parse('2026-09-20'));
      expect(r.note, 'Sân Mỹ Khê 5h chiều nha');
      expect(r.creator?.displayName, 'Anh Ba');
      expect(r.creator?.district, 'Sơn Trà');
      expect(r.creatorRating, 1180.5);
      expect(r.creatorMatchesPlayed, 12);
    });

    test('rating 0 ở môn của kèo → creatorRating null', () {
      final r = MatchRequest.fromJson(requestJson(sport: 'pickleball'));
      expect(r.creatorRating, isNull);
      expect(r.creatorMatchesPlayed, 0);
    });

    test('creator chưa mở môn của kèo → rating & matchesPlayed null', () {
      final json = requestJson();
      (json['creator'] as Map<String, dynamic>)['sport_stats'] = [
        {'sport': 'pickleball', 'rating': 1000, 'matches_played': 3},
      ];
      final r = MatchRequest.fromJson(json);
      expect(r.creatorRating, isNull);
      expect(r.creatorMatchesPlayed, isNull);
    });

    test('responses list + myResponse / acceptedResponse / pendingCount', () {
      final r = MatchRequest.fromJson(requestJson(responses: [
        responseJson(id: 'resp1', responderId: 'me'),
        responseJson(id: 'resp2', responderId: 'other', status: 'accepted'),
        responseJson(id: 'resp3', responderId: 'x', status: 'declined'),
      ]));
      expect(r.responses.length, 3);
      expect(r.myResponse('me')?.id, 'resp1');
      expect(r.myResponse('nobody'), isNull);
      expect(r.acceptedResponse?.id, 'resp2');
      expect(r.acceptedResponse?.responder?.id, 'other');
      expect(r.pendingCount, 1);
    });

    test('không có nested → creator null, responses rỗng', () {
      final r = MatchRequest.fromJson({
        'id': 'req2',
        'sport': 'tennis',
        'creator_id': 'c',
        'status': 'matched',
        'preferred_date': null,
        'note': null,
        'created_at': '2026-09-06T10:00:00Z',
      });
      expect(r.creator, isNull);
      expect(r.creatorRating, isNull);
      expect(r.responses, isEmpty);
      expect(r.preferredDate, isNull);
    });
  });

  group('RequestProfile', () {
    test('displayName fallback', () {
      expect(
        const RequestProfile(id: 'a', fullName: '   ').displayName,
        'Người chơi',
      );
      expect(const RequestProfile(id: 'a').displayName, 'Người chơi');
      expect(
        const RequestProfile(id: 'a', fullName: 'Cường').displayName,
        'Cường',
      );
    });
  });

  group('MatchedContact.fromJson', () {
    test('map đủ field', () {
      final c = MatchedContact.fromJson({
        'profile_id': 'p1',
        'full_name': 'Đối thủ',
        'avatar_url': 'http://x/y.png',
        'phone': '+84900000000',
      });
      expect(c.profileId, 'p1');
      expect(c.fullName, 'Đối thủ');
      expect(c.avatarUrl, 'http://x/y.png');
      expect(c.phone, '+84900000000');
    });

    test('field null', () {
      final c = MatchedContact.fromJson({
        'profile_id': 'p1',
        'full_name': null,
        'avatar_url': null,
        'phone': null,
      });
      expect(c.profileId, 'p1');
      expect(c.phone, isNull);
    });
  });

  group('AvailabilitySlot.fromJson', () {
    test('cắt giây + dayLabel + rangeLabel', () {
      final s = AvailabilitySlot.fromJson({
        'id': 'slot1',
        'sport': 'tennis',
        'day_of_week': 0,
        'start_time': '17:30:00',
        'end_time': '19:00:00',
      });
      expect(s.start, '17:30');
      expect(s.end, '19:00');
      expect(s.dayOfWeek, 0);
      expect(s.dayLabel, 'Thứ 2');
      expect(s.rangeLabel, '17:30–19:00');
    });

    test('day_of_week 6 = Chủ nhật', () {
      final s = AvailabilitySlot.fromJson({
        'id': 'slot2',
        'sport': 'pickleball',
        'day_of_week': 6,
        'start_time': '08:00:00',
        'end_time': '10:00:00',
      });
      expect(s.dayLabel, 'Chủ nhật');
    });

    test('kDayLabels đúng thứ tự 0=Thứ 2 … 6=Chủ nhật', () {
      expect(kDayLabels, [
        'Thứ 2',
        'Thứ 3',
        'Thứ 4',
        'Thứ 5',
        'Thứ 6',
        'Thứ 7',
        'Chủ nhật',
      ]);
    });
  });
}
