import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_super_app/features/auth/application/auth_provider.dart';
import 'package:sport_super_app/features/matches/application/match_provider.dart';
import 'package:sport_super_app/features/matches/data/match_model.dart';
import 'package:sport_super_app/features/matches/data/match_repository.dart';
import 'package:sport_super_app/features/matches/presentation/report_result_screen.dart';
import 'package:sport_super_app/features/profile/application/profile_provider.dart';
import 'package:sport_super_app/features/profile/data/profile_model.dart';

const _me = User(
  id: 'me',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

class _FakeMatchRepo implements MatchRepository {
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
  Future<Profile?> build() async =>
      const Profile(id: 'me', fullName: 'Tôi', currentMode: SportType.tennis);
}

Widget _host() => ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_me),
        matchRepositoryProvider.overrideWithValue(_FakeMatchRepo()),
        myProfileProvider.overrideWith(_FakeProfileNotifier.new),
      ],
      child: const MaterialApp(home: ReportResultScreen()),
    );

ProviderContainer _pc(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(ReportResultScreen)));

ReportMatchController _ctrl(WidgetTester tester) =>
    _pc(tester).read(reportMatchControllerProvider.notifier);

ReportMatchState _state(WidgetTester tester) =>
    _pc(tester).read(reportMatchControllerProvider);

void main() {
  testWidgets('"Ghi kết quả" khoá khi chưa đủ dữ liệu', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    ElevatedButton btn() =>
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Ghi kết quả'));
    expect(btn().onPressed, isNull);

    // đủ đối thủ nhưng tỷ số 0-0 → vẫn khoá + có gợi ý
    _ctrl(tester).addOpponent(const ProfileLite(id: 'foe', fullName: 'Foe'));
    await tester.pump();
    expect(btn().onPressed, isNull);
    expect(find.textContaining('một bên thắng nhiều set hơn'), findsOneWidget);

    // nhập tỷ số có bên thắng → mở khoá
    _ctrl(tester).updateSet(0, a: 6, b: 3);
    await tester.pump();
    expect(btn().onPressed, isNotNull);
  });

  testWidgets('ScoreStepper cộng điểm set cho đội bạn', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final plus = find.byIcon(Icons.add).first; // nút + đầu tiên = "Đội bạn"
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await tester.pump();
    expect(_state(tester).sets.first.a, 1);
  });

  testWidgets('Thêm set tạo thêm hàng ScoreStepper', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final addSet = find.widgetWithText(TextButton, 'Thêm set');
    await tester.ensureVisible(addSet);
    await tester.tap(addSet);
    await tester.pump();
    expect(_state(tester).sets.length, 2);
  });
}
