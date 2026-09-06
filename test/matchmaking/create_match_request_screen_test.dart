import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_super_app/features/auth/application/auth_provider.dart';
import 'package:sport_super_app/features/matchmaking/application/match_request_provider.dart';
import 'package:sport_super_app/features/matchmaking/data/match_request_model.dart';
import 'package:sport_super_app/features/matchmaking/data/match_request_repository.dart';
import 'package:sport_super_app/features/matchmaking/presentation/create_match_request_screen.dart';

const _me = User(
  id: 'me',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

class _FakeRepo implements MatchRequestRepository {
  int createCalls = 0;
  String? lastSport;
  String? lastNote;

  @override
  Future<String> createRequest({
    required String sport,
    DateTime? preferredDate,
    String? note,
  }) async {
    createCalls++;
    lastSport = sport;
    lastNote = note;
    return 'r1';
  }

  @override
  Future<List<MatchRequest>> fetchMyRequests() async => const [];

  @override
  Future<List<MatchRequest>> fetchOpenRequests(String sport) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeSport extends MatchmakingSportNotifier {
  @override
  String build() => 'tennis';
}

Widget _host(_FakeRepo repo) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(_me),
      matchmakingSportProvider.overrideWith(_FakeSport.new),
      matchRequestRepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(home: CreateMatchRequestScreen()),
  );
}

void main() {
  testWidgets('submit gọi createRequest với sport mặc định + SnackBar',
      (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đăng kèo'));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(repo.lastSport, 'tennis');
    expect(find.text('Đã đăng kèo! Chờ người xin vào nhé.'), findsOneWidget);
  });

  testWidgets('đổi môn qua chip → createRequest nhận sport mới', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Pickleball'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đăng kèo'));
    await tester.pumpAndSettle();

    expect(repo.lastSport, 'pickleball');
  });

  testWidgets('lời nhắn được gửi kèm (đã trim)', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  ra sân Mỹ Khê  ');
    await tester.tap(find.text('Đăng kèo'));
    await tester.pumpAndSettle();

    expect(repo.lastNote, 'ra sân Mỹ Khê');
  });
}
