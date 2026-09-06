import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/features/auth/application/auth_provider.dart';
import 'package:sport_super_app/features/matches/application/match_provider.dart';
import 'package:sport_super_app/features/matches/data/match_model.dart';
import 'package:sport_super_app/features/matches/data/match_repository.dart';
import 'package:sport_super_app/features/profile/application/profile_provider.dart';
import 'package:sport_super_app/features/profile/data/profile_model.dart';

/// Fake repo: điều khiển riêng lỗi của hành động (confirm/dispute) và của refetch.
class _FakeMatchRepo implements MatchRepository {
  _FakeMatchRepo({
    this.throwOnAction = false,
    this.throwOnFetch = false,
  });

  bool throwOnAction;
  bool throwOnFetch;
  int confirmCalls = 0;
  int disputeCalls = 0;
  int fetchCalls = 0;

  @override
  Future<void> confirmMatch(String matchId) async {
    confirmCalls++;
    if (throwOnAction) throw Exception('confirm failed');
  }

  @override
  Future<void> disputeMatch(String matchId) async {
    disputeCalls++;
    if (throwOnAction) throw Exception('dispute failed');
  }

  @override
  Future<List<MatchSummary>> fetchMyMatches() async {
    fetchCalls++;
    if (throwOnFetch) throw Exception('network down');
    return const [];
  }

  @override
  Future<String> createMatch({
    required String sport,
    required MatchType matchType,
    required List<String> sideAIds,
    required List<String> sideBIds,
    required List<SetScore> score,
    DateTime? playedAt,
  }) async =>
      'm1';

  @override
  Future<List<ProfileLite>> searchPlayers(String query) async => [];
}

class _FakeProfileNotifier extends MyProfileNotifier {
  @override
  Future<Profile?> build() async => const Profile(id: 'me', fullName: 'Tôi');
}

ProviderContainer _container(_FakeMatchRepo repo) {
  final c = ProviderContainer(overrides: [
    currentUserProvider.overrideWithValue(null),
    matchRepositoryProvider.overrideWithValue(repo),
    myProfileProvider.overrideWith(_FakeProfileNotifier.new),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('MyMatchesNotifier.confirm', () {
    test('confirmMatch OK nhưng refetch lỗi → confirm() KHÔNG ném', () async {
      final repo = _FakeMatchRepo(throwOnFetch: true);
      final c = _container(repo);
      await c.read(myMatchesProvider.future);

      await expectLater(
        c.read(myMatchesProvider.notifier).confirm('m1'),
        completes,
      );
      expect(repo.confirmCalls, 1);
    });

    test('confirmMatch throw → confirm() ném exception', () async {
      final repo = _FakeMatchRepo(throwOnAction: true);
      final c = _container(repo);
      await c.read(myMatchesProvider.future);

      await expectLater(
        c.read(myMatchesProvider.notifier).confirm('m1'),
        throwsA(isA<Exception>()),
      );
      expect(repo.confirmCalls, 1);
      // Hành động lỗi → không refetch (build với user null cũng không fetch).
      expect(repo.fetchCalls, 0);
    });
  });

  group('MyMatchesNotifier.dispute', () {
    test('disputeMatch OK nhưng refetch lỗi → dispute() KHÔNG ném', () async {
      final repo = _FakeMatchRepo(throwOnFetch: true);
      final c = _container(repo);
      await c.read(myMatchesProvider.future);

      await expectLater(
        c.read(myMatchesProvider.notifier).dispute('m1'),
        completes,
      );
      expect(repo.disputeCalls, 1);
    });

    test('disputeMatch throw → dispute() ném exception', () async {
      final repo = _FakeMatchRepo(throwOnAction: true);
      final c = _container(repo);
      await c.read(myMatchesProvider.future);

      await expectLater(
        c.read(myMatchesProvider.notifier).dispute('m1'),
        throwsA(isA<Exception>()),
      );
      expect(repo.disputeCalls, 1);
    });
  });
}
