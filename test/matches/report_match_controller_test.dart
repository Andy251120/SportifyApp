import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/features/matches/application/match_provider.dart';
import 'package:sport_super_app/features/matches/data/match_model.dart';
import 'package:sport_super_app/features/matches/data/match_repository.dart';
import 'package:sport_super_app/features/profile/application/profile_provider.dart';
import 'package:sport_super_app/features/profile/data/profile_model.dart';

class _FakeMatchRepo implements MatchRepository {
  Map<String, dynamic>? lastCreate;

  @override
  Future<String> createMatch({
    required String sport,
    required MatchType matchType,
    required List<String> sideAIds,
    required List<String> sideBIds,
    required List<SetScore> score,
    DateTime? playedAt,
  }) async {
    lastCreate = {
      'sport': sport,
      'type': matchType,
      'a': sideAIds,
      'b': sideBIds,
      'sets': score.length,
    };
    return 'match-123';
  }

  @override
  Future<List<MatchSummary>> fetchMyMatches() async => [];
  @override
  Future<void> confirmMatch(String matchId) async {}
  @override
  Future<void> disputeMatch(String matchId) async {}
  @override
  Future<List<ProfileLite>> searchPlayers(String query) async => [];
}

class _FakeProfileNotifier extends MyProfileNotifier {
  @override
  Future<Profile?> build() async => const Profile(
        id: 'me',
        fullName: 'Tôi',
        currentMode: SportType.pickleball,
        stats: [],
      );
}

ProviderContainer _container(_FakeMatchRepo repo) {
  final c = ProviderContainer(overrides: [
    matchRepositoryProvider.overrideWithValue(repo),
    myProfileProvider.overrideWith(_FakeProfileNotifier.new),
  ]);
  addTearDown(c.dispose);
  return c;
}

const _p1 = ProfileLite(id: 'p1', fullName: 'An');
const _p2 = ProfileLite(id: 'p2', fullName: 'Bình');
const _p3 = ProfileLite(id: 'p3', fullName: 'Cường');

void main() {
  test('seed sport theo current_mode của hồ sơ', () async {
    final c = _container(_FakeMatchRepo());
    await c.read(myProfileProvider.future);
    expect(c.read(reportMatchControllerProvider).sport, 'pickleball');
  });

  test('canSubmit: đơn cần đúng 1 đối thủ + có set', () async {
    final c = _container(_FakeMatchRepo());
    final ctrl = c.read(reportMatchControllerProvider.notifier);

    expect(c.read(reportMatchControllerProvider).canSubmit, isFalse);
    ctrl.addOpponent(_p1);
    expect(c.read(reportMatchControllerProvider).canSubmit, isTrue);
    // không thêm được đối thủ thứ 2 khi đánh đơn
    ctrl.addOpponent(_p2);
    expect(c.read(reportMatchControllerProvider).opponents, hasLength(1));
  });

  test('đổi sang đôi: reset đối thủ, cần đồng đội + 2 đối thủ', () async {
    final c = _container(_FakeMatchRepo());
    final ctrl = c.read(reportMatchControllerProvider.notifier);
    ctrl.addOpponent(_p1);
    ctrl.setMatchType(MatchType.doubles);
    expect(c.read(reportMatchControllerProvider).opponents, isEmpty);

    ctrl.addOpponent(_p1);
    ctrl.addOpponent(_p2);
    expect(c.read(reportMatchControllerProvider).canSubmit, isFalse); // thiếu đồng đội
    ctrl.setPartner(_p3);
    expect(c.read(reportMatchControllerProvider).canSubmit, isTrue);
  });

  test('submit gửi đúng danh sách 2 bên (bạn + đồng đội / đối thủ)', () async {
    final repo = _FakeMatchRepo();
    final c = _container(repo);
    final ctrl = c.read(reportMatchControllerProvider.notifier);
    ctrl.setMatchType(MatchType.doubles);
    ctrl.setPartner(_p3);
    ctrl.addOpponent(_p1);
    ctrl.addOpponent(_p2);
    ctrl.updateSet(0, a: 11, b: 7);

    final ok = await ctrl.submit('me');
    expect(ok, isTrue);
    expect(repo.lastCreate!['a'], ['me', 'p3']);
    expect(repo.lastCreate!['b'], ['p1', 'p2']);
    expect(repo.lastCreate!['type'], MatchType.doubles);
  });

  test('addSet / removeSet giới hạn 1..5', () async {
    final c = _container(_FakeMatchRepo());
    final ctrl = c.read(reportMatchControllerProvider.notifier);
    for (var i = 0; i < 10; i++) {
      ctrl.addSet();
    }
    expect(c.read(reportMatchControllerProvider).sets.length, 5);
    for (var i = 0; i < 10; i++) {
      ctrl.removeSet(0);
    }
    expect(c.read(reportMatchControllerProvider).sets.length, 1);
  });
}
