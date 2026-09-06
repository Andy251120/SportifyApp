import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_super_app/features/auth/application/auth_provider.dart';
import 'package:sport_super_app/features/matchmaking/application/availability_provider.dart';
import 'package:sport_super_app/features/matchmaking/data/availability_model.dart';
import 'package:sport_super_app/features/matchmaking/presentation/availability_editor_screen.dart';

const _me = User(
  id: 'me',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

AvailabilitySlot _slot({
  required String id,
  required String sport,
  int day = 0,
  String start = '08:00',
  String end = '10:00',
}) =>
    AvailabilitySlot(
        id: id, sport: sport, dayOfWeek: day, start: start, end: end);

class _FakeAvail extends MyAvailabilityNotifier {
  _FakeAvail(this._data);
  final List<AvailabilitySlot> _data;

  @override
  Future<List<AvailabilitySlot>> build() async => _data;
}

Widget _host(List<AvailabilitySlot> slots) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(_me),
      myAvailabilityProvider.overrideWith(() => _FakeAvail(slots)),
    ],
    child: const MaterialApp(home: AvailabilityEditorScreen()),
  );
}

void main() {
  group('availabilityRangeValid', () {
    test('null → false', () {
      expect(availabilityRangeValid(null, null), isFalse);
      expect(
          availabilityRangeValid(const TimeOfDay(hour: 8, minute: 0), null),
          isFalse);
    });

    test('start < end → true', () {
      expect(
        availabilityRangeValid(const TimeOfDay(hour: 8, minute: 0),
            const TimeOfDay(hour: 10, minute: 0)),
        isTrue,
      );
    });

    test('start >= end → false', () {
      expect(
        availabilityRangeValid(const TimeOfDay(hour: 10, minute: 0),
            const TimeOfDay(hour: 8, minute: 0)),
        isFalse,
      );
      expect(
        availabilityRangeValid(const TimeOfDay(hour: 9, minute: 0),
            const TimeOfDay(hour: 9, minute: 0)),
        isFalse,
      );
    });
  });

  testWidgets('render slot theo nhóm môn', (tester) async {
    await tester.pumpWidget(_host([
      _slot(id: 's1', sport: 'tennis', day: 0),
      _slot(id: 's2', sport: 'pickleball', day: 6),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Tennis'), findsOneWidget);
    expect(find.text('Pickleball'), findsOneWidget);
    expect(find.text('Thứ 2 · 08:00–10:00'), findsOneWidget);
    expect(find.text('Chủ nhật · 08:00–10:00'), findsOneWidget);
  });

  testWidgets('chưa đặt khung giờ → empty state', (tester) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chưa đặt khung giờ nào'), findsWidgets);
  });

  testWidgets('sheet thêm khung giờ: nút Lưu bị chặn khi chưa chọn giờ',
      (tester) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm khung giờ'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm khung giờ rảnh'), findsOneWidget);
    final saveButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Lưu'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(saveButton.onPressed, isNull);
  });
}
