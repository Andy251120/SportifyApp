import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_super_app/features/auth/application/auth_provider.dart';
import 'package:sport_super_app/features/matchmaking/application/match_request_provider.dart';
import 'package:sport_super_app/features/matchmaking/data/match_request_model.dart';
import 'package:sport_super_app/features/matchmaking/data/match_request_repository.dart';
import 'package:sport_super_app/features/profile/application/profile_provider.dart';
import 'package:sport_super_app/features/profile/data/profile_model.dart';

/// Fake: điều khiển riêng lỗi hành động vs lỗi refetch, đếm số lần gọi.
class _FakeRequestRepo implements MatchRequestRepository {
  _FakeRequestRepo({this.throwOnAction = false, this.throwOnFetch = false});

  bool throwOnAction;
  bool throwOnFetch;

  int respondCalls = 0;
  int withdrawCalls = 0;
  int cancelCalls = 0;
  int acceptCalls = 0;
  int createCalls = 0;
  int fetchOpenCalls = 0;
  int fetchMineCalls = 0;
  int fetchRespondedCalls = 0;
  List<MatchRequest> respondedData = const [];
  String? lastAcceptId;
  Map<String, dynamic>? lastCreateArgs;

  @override
  Future<List<MatchRequest>> fetchOpenRequests(String sport) async {
    fetchOpenCalls++;
    if (throwOnFetch) throw Exception('network down');
    return const [];
  }

  @override
  Future<List<MatchRequest>> fetchRespondedRequests() async {
    fetchRespondedCalls++;
    if (throwOnFetch) throw Exception('network down');
    return respondedData;
  }

  @override
  Future<List<MatchRequest>> fetchMyRequests() async {
    fetchMineCalls++;
    if (throwOnFetch) throw Exception('network down');
    return const [];
  }

  @override
  Future<MatchRequest> fetchRequest(String id) async =>
      throw UnimplementedError();

  @override
  Future<String> createRequest({
    required String sport,
    DateTime? preferredDate,
    String? note,
  }) async {
    createCalls++;
    lastCreateArgs = {
      'sport': sport,
      'preferredDate': preferredDate,
      'note': note,
    };
    if (throwOnAction) throw Exception('create failed');
    return 'req1';
  }

  @override
  Future<void> cancelRequest(String id) async {
    cancelCalls++;
    if (throwOnAction) throw Exception('cancel failed');
  }

  @override
  Future<void> respond(String requestId) async {
    respondCalls++;
    if (throwOnAction) throw Exception('respond failed');
  }

  @override
  Future<void> withdrawResponse(String responseId) async {
    withdrawCalls++;
    if (throwOnAction) throw Exception('withdraw failed');
  }

  @override
  Future<String> acceptResponse(String responseId) async {
    acceptCalls++;
    lastAcceptId = responseId;
    if (throwOnAction) throw Exception('accept failed');
    return 'req1';
  }

  @override
  Future<MatchedContact?> matchedContact(String requestId) async => null;
}

class _FakeProfileNotifier extends MyProfileNotifier {
  _FakeProfileNotifier(this._mode);
  final SportType _mode;

  @override
  Future<Profile?> build() async =>
      Profile(id: 'me', fullName: 'Tôi', currentMode: _mode);
}

const _me = User(
  id: 'me',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

MatchRequest _req(String id) => MatchRequest(
      id: id,
      sport: 'tennis',
      creatorId: 'creator1',
      status: MatchRequestStatus.open,
      createdAt: DateTime(2026, 1, 1),
    );

ProviderContainer _container(
  _FakeRequestRepo repo, {
  SportType mode = SportType.tennis,
  User? user,
}) {
  final c = ProviderContainer(overrides: [
    currentUserProvider.overrideWithValue(user),
    matchRequestRepositoryProvider.overrideWithValue(repo),
    myProfileProvider.overrideWith(() => _FakeProfileNotifier(mode)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('matchmakingSportProvider', () {
    test('seed từ profiles.current_mode', () async {
      final c = _container(_FakeRequestRepo(), mode: SportType.pickleball);
      await c.read(myProfileProvider.future);
      expect(c.read(matchmakingSportProvider), 'pickleball');
    });

    test('set() đổi giá trị', () async {
      final c = _container(_FakeRequestRepo());
      await c.read(myProfileProvider.future);
      expect(c.read(matchmakingSportProvider), 'tennis');
      c.read(matchmakingSportProvider.notifier).set('pickleball');
      expect(c.read(matchmakingSportProvider), 'pickleball');
    });
  });

  group('OpenRequestsNotifier.respond', () {
    test('respond OK nhưng refetch lỗi → KHÔNG ném', () async {
      final repo = _FakeRequestRepo(throwOnFetch: true);
      final c = _container(repo);
      await c.read(openRequestsProvider.future);

      await expectLater(
        c.read(openRequestsProvider.notifier).respond('req1'),
        completes,
      );
      expect(repo.respondCalls, 1);
    });

    test('respond throw → CÓ ném exception', () async {
      final repo = _FakeRequestRepo(throwOnAction: true);
      final c = _container(repo);
      await c.read(openRequestsProvider.future);

      await expectLater(
        c.read(openRequestsProvider.notifier).respond('req1'),
        throwsA(isA<Exception>()),
      );
      expect(repo.respondCalls, 1);
    });

    test('withdraw OK nhưng refetch lỗi → KHÔNG ném', () async {
      final repo = _FakeRequestRepo(throwOnFetch: true);
      final c = _container(repo);
      await c.read(openRequestsProvider.future);

      await expectLater(
        c.read(openRequestsProvider.notifier).withdraw('resp1'),
        completes,
      );
      expect(repo.withdrawCalls, 1);
    });

    test('withdraw throw → CÓ ném exception', () async {
      final repo = _FakeRequestRepo(throwOnAction: true);
      final c = _container(repo);
      await c.read(openRequestsProvider.future);

      await expectLater(
        c.read(openRequestsProvider.notifier).withdraw('resp1'),
        throwsA(isA<Exception>()),
      );
      expect(repo.withdrawCalls, 1);
    });
  });

  group('MyRequestsNotifier', () {
    test('accept gọi đúng acceptResponse của repo + trả match_request_id',
        () async {
      final repo = _FakeRequestRepo();
      final c = _container(repo);
      await c.read(myRequestsProvider.future);

      final id = await c.read(myRequestsProvider.notifier).accept('resp9');
      expect(id, 'req1');
      expect(repo.acceptCalls, 1);
      expect(repo.lastAcceptId, 'resp9');
    });

    test('accept throw → CÓ ném, không refetch', () async {
      final repo = _FakeRequestRepo(throwOnAction: true);
      final c = _container(repo);
      await c.read(myRequestsProvider.future);
      repo.fetchMineCalls = 0;

      await expectLater(
        c.read(myRequestsProvider.notifier).accept('resp9'),
        throwsA(isA<Exception>()),
      );
      expect(repo.acceptCalls, 1);
      expect(repo.fetchMineCalls, 0);
    });

    test('cancel OK nhưng refetch lỗi → KHÔNG ném', () async {
      final repo = _FakeRequestRepo(throwOnFetch: true);
      final c = _container(repo);
      await c.read(myRequestsProvider.future);

      await expectLater(
        c.read(myRequestsProvider.notifier).cancel('req1'),
        completes,
      );
      expect(repo.cancelCalls, 1);
    });

    test('cancel throw → CÓ ném exception', () async {
      final repo = _FakeRequestRepo(throwOnAction: true);
      final c = _container(repo);
      await c.read(myRequestsProvider.future);

      await expectLater(
        c.read(myRequestsProvider.notifier).cancel('req1'),
        throwsA(isA<Exception>()),
      );
      expect(repo.cancelCalls, 1);
    });
  });

  group('RespondedRequestsNotifier', () {
    test('build ra list từ repo khi có user', () async {
      final repo = _FakeRequestRepo()..respondedData = [_req('r1'), _req('r2')];
      final c = _container(repo, user: _me);

      final list = await c.read(respondedRequestsProvider.future);
      expect(list, hasLength(2));
      expect(repo.fetchRespondedCalls, 1);
    });

    test('user null → [] và không gọi repo', () async {
      final repo = _FakeRequestRepo()..respondedData = [_req('r1')];
      final c = _container(repo);

      final list = await c.read(respondedRequestsProvider.future);
      expect(list, isEmpty);
      expect(repo.fetchRespondedCalls, 0);
    });

    test('respond() → invalidate respondedRequestsProvider (refetch)', () async {
      final repo = _FakeRequestRepo()..respondedData = [_req('r1')];
      final c = _container(repo, user: _me);
      await c.read(respondedRequestsProvider.future);
      expect(repo.fetchRespondedCalls, 1);

      await c.read(openRequestsProvider.notifier).respond('r1');
      await c.read(respondedRequestsProvider.future);
      expect(repo.fetchRespondedCalls, 2);
    });

    test('withdraw() → invalidate respondedRequestsProvider (refetch)', () async {
      final repo = _FakeRequestRepo()..respondedData = [_req('r1')];
      final c = _container(repo, user: _me);
      await c.read(respondedRequestsProvider.future);

      await c.read(openRequestsProvider.notifier).withdraw('resp1');
      await c.read(respondedRequestsProvider.future);
      expect(repo.fetchRespondedCalls, 2);
    });

    test('accept() → invalidate respondedRequestsProvider (refetch)', () async {
      final repo = _FakeRequestRepo()..respondedData = [_req('r1')];
      final c = _container(repo, user: _me);
      await c.read(respondedRequestsProvider.future);

      await c.read(myRequestsProvider.notifier).accept('resp9');
      await c.read(respondedRequestsProvider.future);
      expect(repo.fetchRespondedCalls, 2);
    });
  });

  group('visibleRespondedRequests', () {
    MatchRequest req(
      String id, {
      MatchRequestStatus status = MatchRequestStatus.open,
      ResponseStatus? myStatus,
    }) =>
        MatchRequest(
          id: id,
          sport: 'tennis',
          creatorId: 'creator1',
          status: status,
          createdAt: DateTime(2026, 1, 1),
          responses: myStatus == null
              ? const []
              : [
                  MatchRequestResponse(
                    id: 'resp-$id',
                    matchRequestId: id,
                    responderId: 'me',
                    status: myStatus,
                    createdAt: DateTime(2026, 1, 1),
                  ),
                ],
        );

    test('pending + kèo open → bị loại (đã hiện ở "Kèo đang mở")', () {
      final out = visibleRespondedRequests(
        [req('r1', myStatus: ResponseStatus.pending)],
        'me',
      );
      expect(out, isEmpty);
    });

    test('declined + kèo open (tôi tự rút) → bị loại', () {
      final out = visibleRespondedRequests(
        [req('r1', myStatus: ResponseStatus.declined)],
        'me',
      );
      expect(out, isEmpty);
    });

    test('declined + kèo matched (chủ chọn người khác) → giữ', () {
      final out = visibleRespondedRequests(
        [
          req('r1',
              status: MatchRequestStatus.matched,
              myStatus: ResponseStatus.declined),
        ],
        'me',
      );
      expect(out.map((r) => r.id), ['r1']);
    });

    test('accepted → luôn giữ dù kèo ở trạng thái nào', () {
      final out = visibleRespondedRequests(
        [
          req('r1', myStatus: ResponseStatus.accepted),
          req('r2',
              status: MatchRequestStatus.matched,
              myStatus: ResponseStatus.accepted),
        ],
        'me',
      );
      expect(out.map((r) => r.id), ['r1', 'r2']);
    });

    test('không có response của tôi → bị loại', () {
      final out = visibleRespondedRequests([req('r1')], 'me');
      expect(out, isEmpty);
    });
  });

  group('CreateMatchRequestController', () {
    test('seed sport theo matchmakingSportProvider', () async {
      final c = _container(_FakeRequestRepo(), mode: SportType.pickleball);
      await c.read(myProfileProvider.future);
      expect(
        c.read(createMatchRequestControllerProvider).sport,
        'pickleball',
      );
    });

    test('submit gọi createRequest với sport + note đã trim, trả true', () async {
      final repo = _FakeRequestRepo();
      final c = _container(repo);
      await c.read(myProfileProvider.future);
      final ctrl = c.read(createMatchRequestControllerProvider.notifier);

      ctrl.setSport('pickleball');
      ctrl.setNote('  tối nay ra sân nhé  ');
      final date = DateTime(2026, 9, 20);
      ctrl.setDate(date);

      final ok = await ctrl.submit();
      expect(ok, isTrue);
      expect(repo.createCalls, 1);
      expect(repo.lastCreateArgs, {
        'sport': 'pickleball',
        'preferredDate': date,
        'note': 'tối nay ra sân nhé',
      });
    });

    test('note rỗng → gửi null', () async {
      final repo = _FakeRequestRepo();
      final c = _container(repo);
      await c.read(myProfileProvider.future);
      final ctrl = c.read(createMatchRequestControllerProvider.notifier);

      ctrl.setNote('   ');
      final ok = await ctrl.submit();
      expect(ok, isTrue);
      expect(repo.lastCreateArgs!['note'], isNull);
    });

    test('createRequest ném → submit trả false + set error', () async {
      final repo = _FakeRequestRepo(throwOnAction: true);
      final c = _container(repo);
      await c.read(myProfileProvider.future);
      final ctrl = c.read(createMatchRequestControllerProvider.notifier);

      final ok = await ctrl.submit();
      expect(ok, isFalse);
      expect(c.read(createMatchRequestControllerProvider).error, isNotNull);
      expect(c.read(createMatchRequestControllerProvider).submitting, isFalse);
    });
  });
}
