import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_super_app/features/auth/application/auth_provider.dart';
import 'package:sport_super_app/features/matches/application/match_provider.dart';
import 'package:sport_super_app/features/matches/data/match_model.dart';
import 'package:sport_super_app/features/matches/presentation/confirm_result_screen.dart';

const _me = User(
  id: 'me',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

MatchSummary _match({
  required String id,
  required MatchStatus status,
  required String reportedBy,
  double? myRatingAfter,
}) {
  return MatchSummary(
    id: id,
    sport: 'tennis',
    matchType: MatchType.singles,
    score: const [SetScore(a: 6, b: 3), SetScore(a: 6, b: 4)],
    status: status,
    reportedBy: reportedBy,
    playedAt: DateTime(2026, 1, 1),
    reportedAt: DateTime(2026, 1, 1),
    autoConfirmed: false,
    participants: [
      MatchParticipant(
        profileId: 'me',
        side: 'a',
        ratingAfter: myRatingAfter,
        profile: const ProfileLite(id: 'me', fullName: 'Tôi'),
      ),
      const MatchParticipant(
        profileId: 'foe',
        side: 'b',
        profile: ProfileLite(id: 'foe', fullName: 'Đối Thủ'),
      ),
    ],
  );
}

class _FakeMatches extends MyMatchesNotifier {
  _FakeMatches(this._data);
  final List<MatchSummary> _data;
  int confirmCalls = 0;

  @override
  Future<List<MatchSummary>> build() async => _data;

  @override
  Future<void> confirm(String matchId) async {
    confirmCalls++;
  }
}

Widget _host(List<MatchSummary> data, {_FakeMatches? notifier}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(_me),
      myMatchesProvider.overrideWith(() => notifier ?? _FakeMatches(data)),
    ],
    child: const MaterialApp(home: ConfirmResultScreen()),
  );
}

void main() {
  testWidgets('không có trận → empty state thân thiện', (tester) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có trận nào'), findsOneWidget);
  });

  testWidgets('trận cần xác nhận: hiện đối thủ + 2 nút hành động', (tester) async {
    await tester.pumpWidget(_host([
      _match(id: 'm1', status: MatchStatus.pendingConfirmation, reportedBy: 'foe'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Cần bạn xác nhận'), findsOneWidget);
    expect(find.textContaining('vs Đối Thủ'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Từ chối'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);
  });

  testWidgets('trận mình báo cáo → nằm ở "Trận gần đây", không có nút', (tester) async {
    await tester.pumpWidget(_host([
      _match(id: 'm2', status: MatchStatus.pendingConfirmation, reportedBy: 'me'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Cần bạn xác nhận'), findsNothing);
    expect(find.text('Trận gần đây'), findsOneWidget);
    expect(find.text('Xác nhận'), findsNothing);
    expect(find.text('⏳ Chờ đối thủ'), findsOneWidget);
  });

  testWidgets('trận đã confirmed hiện điểm trình mới', (tester) async {
    await tester.pumpWidget(_host([
      _match(
        id: 'm3',
        status: MatchStatus.confirmed,
        reportedBy: 'foe',
        myRatingAfter: 1016,
      ),
    ]));
    await tester.pumpAndSettle();
    expect(find.textContaining('Điểm trình mới: 1016'), findsOneWidget);
  });

  testWidgets('bấm "Xác nhận" → hỏi lại → gọi notifier.confirm', (tester) async {
    final notifier = _FakeMatches([
      _match(id: 'm1', status: MatchStatus.pendingConfirmation, reportedBy: 'foe'),
    ]);
    await tester.pumpWidget(_host(const [], notifier: notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    // dialog xác nhận
    expect(find.text('Xác nhận kết quả này?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Xác nhận'));
    await tester.pumpAndSettle();

    expect(notifier.confirmCalls, 1);
  });
}
