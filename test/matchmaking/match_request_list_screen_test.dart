import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_super_app/features/auth/application/auth_provider.dart';
import 'package:sport_super_app/features/matchmaking/application/match_request_provider.dart';
import 'package:sport_super_app/features/matchmaking/data/match_request_model.dart';
import 'package:sport_super_app/features/matchmaking/presentation/match_request_list_screen.dart';

const _me = User(
  id: 'me',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

MatchRequest _req({
  required String id,
  String creatorId = 'creator1',
  MatchRequestStatus status = MatchRequestStatus.open,
  String? note,
  List<MatchRequestResponse> responses = const [],
}) {
  return MatchRequest(
    id: id,
    sport: 'tennis',
    creatorId: creatorId,
    status: status,
    note: note,
    createdAt: DateTime(2026, 1, 1),
    creator: const RequestProfile(
        id: 'creator1', fullName: 'Anh Ba', district: 'Sơn Trà'),
    responses: responses,
  );
}

MatchRequestResponse _resp({
  required String id,
  String responderId = 'me',
  ResponseStatus status = ResponseStatus.pending,
}) =>
    MatchRequestResponse(
      id: id,
      matchRequestId: 'r1',
      responderId: responderId,
      status: status,
      createdAt: DateTime(2026, 1, 1),
    );

class _FakeOpen extends OpenRequestsNotifier {
  _FakeOpen(this._data);
  final List<MatchRequest> _data;
  int respondCalls = 0;
  String? lastRespondId;

  @override
  Future<List<MatchRequest>> build() async => _data;

  @override
  Future<void> respond(String requestId) async {
    respondCalls++;
    lastRespondId = requestId;
  }
}

class _FakeMine extends MyRequestsNotifier {
  _FakeMine(this._data);
  final List<MatchRequest> _data;

  @override
  Future<List<MatchRequest>> build() async => _data;
}

class _FakeResponded extends RespondedRequestsNotifier {
  _FakeResponded(this._data);
  final List<MatchRequest> _data;

  @override
  Future<List<MatchRequest>> build() async => _data;
}

class _FakeSport extends MatchmakingSportNotifier {
  @override
  String build() => 'tennis';
}

Widget _host({
  List<MatchRequest> open = const [],
  List<MatchRequest> mine = const [],
  List<MatchRequest> responded = const [],
  _FakeOpen? openNotifier,
}) {
  final router = GoRouter(
    initialLocation: '/matchmaking',
    routes: [
      GoRoute(
        path: '/matchmaking',
        builder: (_, __) => const Scaffold(body: MatchRequestListScreen()),
      ),
      GoRoute(
        path: '/matchmaking/:id',
        builder: (_, state) =>
            Scaffold(body: Text('DETAIL ${state.pathParameters['id']}')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(_me),
      matchmakingSportProvider.overrideWith(_FakeSport.new),
      openRequestsProvider.overrideWith(() => openNotifier ?? _FakeOpen(open)),
      myRequestsProvider.overrideWith(() => _FakeMine(mine)),
      respondedRequestsProvider.overrideWith(() => _FakeResponded(responded)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('render 2 mục: Kèo của tôi + Kèo đang mở', (tester) async {
    await tester.pumpWidget(_host(
      mine: [_req(id: 'r1', creatorId: 'me', note: 'Kèo tối nay')],
      open: [_req(id: 'r2', note: 'Ai rảnh không')],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Kèo của tôi'), findsOneWidget);
    expect(find.text('Kèo đang mở'), findsOneWidget);
    expect(find.text('Kèo tối nay'), findsOneWidget);
    expect(find.text('Ai rảnh không'), findsOneWidget);
    expect(find.text('Anh Ba'), findsOneWidget);
  });

  testWidgets('_OpenRequestCard hiện "Xin vào kèo" khi chưa respond',
      (tester) async {
    await tester.pumpWidget(_host(open: [_req(id: 'r2')]));
    await tester.pumpAndSettle();

    expect(find.text('Xin vào kèo'), findsOneWidget);
  });

  testWidgets('_OpenRequestCard hiện "Chờ chủ kèo duyệt" khi pending',
      (tester) async {
    await tester.pumpWidget(_host(open: [
      _req(id: 'r2', responses: [_resp(id: 'resp1')]),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('⏳ Chờ chủ kèo duyệt'), findsOneWidget);
    expect(find.text('Xin vào kèo'), findsNothing);
  });

  testWidgets('tap "Xin vào kèo" gọi notifier.respond', (tester) async {
    final openNotifier = _FakeOpen([_req(id: 'r2')]);
    await tester.pumpWidget(_host(openNotifier: openNotifier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xin vào kèo'));
    await tester.pumpAndSettle();

    expect(openNotifier.respondCalls, 1);
    expect(openNotifier.lastRespondId, 'r2');
  });

  testWidgets('không có kèo mở → empty state thân thiện', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.textContaining('Chưa có kèo nào đang mở'), findsWidgets);
  });

  testWidgets('section "Kèo tôi đã xin vào" ẩn khi list rỗng', (tester) async {
    await tester.pumpWidget(_host(open: [_req(id: 'r2')]));
    await tester.pumpAndSettle();

    expect(find.text('Kèo tôi đã xin vào'), findsNothing);
  });

  testWidgets('kèo đã xin vào + accepted → section hiện, chip "Đã ghép"',
      (tester) async {
    await tester.pumpWidget(_host(responded: [
      _req(id: 'r5', note: 'Kèo đôi tối nay', responses: [
        _resp(id: 'x1', status: ResponseStatus.accepted),
      ]),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Kèo tôi đã xin vào'), findsOneWidget);
    expect(find.text('✅ Đã ghép — xem SĐT'), findsOneWidget);
  });

  testWidgets('responded: open + pending → KHÔNG hiện ở section 3 (tránh trùng)',
      (tester) async {
    await tester.pumpWidget(_host(responded: [
      _req(id: 'r6', note: 'Kèo còn mở', responses: [
        _resp(id: 'p1'),
      ]),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Kèo tôi đã xin vào'), findsNothing);
    expect(find.text('Kèo còn mở'), findsNothing);
  });

  testWidgets('responded: open + declined (tự rút) → KHÔNG hiện ở section 3',
      (tester) async {
    await tester.pumpWidget(_host(responded: [
      _req(id: 'r7', note: 'Kèo tôi rút', responses: [
        _resp(id: 'd1', status: ResponseStatus.declined),
      ]),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Kèo tôi đã xin vào'), findsNothing);
    expect(find.text('Kèo tôi rút'), findsNothing);
  });

  testWidgets('responded: matched + declined → hiện, chip "chọn người khác"',
      (tester) async {
    await tester.pumpWidget(_host(responded: [
      _req(
        id: 'r8',
        note: 'Kèo mất suất',
        status: MatchRequestStatus.matched,
        responses: [_resp(id: 'd2', status: ResponseStatus.declined)],
      ),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Kèo tôi đã xin vào'), findsOneWidget);
    expect(find.text('Kèo mất suất'), findsOneWidget);
    expect(find.text('Chủ kèo chọn người khác rồi'), findsOneWidget);
  });

  testWidgets('responded: matched + accepted → hiện, chip "Đã ghép — xem SĐT"',
      (tester) async {
    await tester.pumpWidget(_host(responded: [
      _req(
        id: 'r9',
        note: 'Kèo đã chốt',
        status: MatchRequestStatus.matched,
        responses: [_resp(id: 'a2', status: ResponseStatus.accepted)],
      ),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Kèo tôi đã xin vào'), findsOneWidget);
    expect(find.text('✅ Đã ghép — xem SĐT'), findsOneWidget);
  });

  testWidgets('tap card "Kèo tôi đã xin vào" → điều hướng /matchmaking/:id',
      (tester) async {
    await tester.pumpWidget(_host(responded: [
      _req(id: 'r5', note: 'Kèo đôi tối nay', responses: [
        _resp(id: 'x1', status: ResponseStatus.accepted),
      ]),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kèo đôi tối nay'));
    await tester.pumpAndSettle();

    expect(find.text('DETAIL r5'), findsOneWidget);
  });
}
