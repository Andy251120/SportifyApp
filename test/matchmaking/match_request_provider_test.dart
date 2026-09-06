import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  int fetchOpenCalls = 0;
  int fetchMineCalls = 0;
  String? lastAcceptId;

  @override
  Future<List<MatchRequest>> fetchOpenRequests(String sport) async {
    fetchOpenCalls++;
    if (throwOnFetch) throw Exception('network down');
    return const [];
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
  }) async =>
      'req1';

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

ProviderContainer _container(
  _FakeRequestRepo repo, {
  SportType mode = SportType.tennis,
}) {
  final c = ProviderContainer(overrides: [
    currentUserProvider.overrideWithValue(null),
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
  });
}
