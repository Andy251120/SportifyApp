import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/features/auth/application/auth_provider.dart';
import 'package:sport_super_app/features/matchmaking/application/availability_provider.dart';
import 'package:sport_super_app/features/matchmaking/data/availability_model.dart';
import 'package:sport_super_app/features/matchmaking/data/availability_repository.dart';

class _FakeAvailabilityRepo implements AvailabilityRepository {
  _FakeAvailabilityRepo({this.throwOnAction = false, this.throwOnFetch = false});

  bool throwOnAction;
  bool throwOnFetch;

  int fetchCalls = 0;
  int deleteCalls = 0;
  String? lastDeletedId;
  Map<String, dynamic>? lastAddArgs;

  @override
  Future<List<AvailabilitySlot>> fetchMyAvailability() async {
    fetchCalls++;
    if (throwOnFetch) throw Exception('network down');
    return const [];
  }

  @override
  Future<void> addSlot({
    required String sport,
    required int dayOfWeek,
    required String start,
    required String end,
  }) async {
    lastAddArgs = {
      'sport': sport,
      'dayOfWeek': dayOfWeek,
      'start': start,
      'end': end,
    };
    if (throwOnAction) throw Exception('add failed');
  }

  @override
  Future<void> deleteSlot(String id) async {
    deleteCalls++;
    lastDeletedId = id;
    if (throwOnAction) throw Exception('delete failed');
  }

  @override
  Future<List<AvailabilitySlot>> fetchAvailabilityFor(
          String profileId, String sport) async =>
      const [];
}

ProviderContainer _container(_FakeAvailabilityRepo repo) {
  final c = ProviderContainer(overrides: [
    currentUserProvider.overrideWithValue(null),
    availabilityRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('AvailabilityRepository.toDbTime: "HH:mm" → "HH:mm:00"', () {
    expect(AvailabilityRepository.toDbTime('17:30'), '17:30:00');
    expect(AvailabilityRepository.toDbTime('08:00'), '08:00:00');
  });

  group('MyAvailabilityNotifier.addSlot', () {
    test('gửi đúng tham số ("HH:mm" giữ nguyên, repo tự thêm giây)', () async {
      final repo = _FakeAvailabilityRepo();
      final c = _container(repo);
      await c.read(myAvailabilityProvider.future);

      await c.read(myAvailabilityProvider.notifier).addSlot(
            sport: 'tennis',
            dayOfWeek: 2,
            start: '17:30',
            end: '19:00',
          );

      expect(repo.lastAddArgs, {
        'sport': 'tennis',
        'dayOfWeek': 2,
        'start': '17:30',
        'end': '19:00',
      });
    });

    test('addSlot OK nhưng refetch lỗi → KHÔNG ném', () async {
      final repo = _FakeAvailabilityRepo(throwOnFetch: true);
      final c = _container(repo);
      await c.read(myAvailabilityProvider.future);

      await expectLater(
        c.read(myAvailabilityProvider.notifier).addSlot(
              sport: 'tennis',
              dayOfWeek: 0,
              start: '08:00',
              end: '09:00',
            ),
        completes,
      );
    });

    test('addSlot throw → CÓ ném exception', () async {
      final repo = _FakeAvailabilityRepo(throwOnAction: true);
      final c = _container(repo);
      await c.read(myAvailabilityProvider.future);

      await expectLater(
        c.read(myAvailabilityProvider.notifier).addSlot(
              sport: 'tennis',
              dayOfWeek: 0,
              start: '08:00',
              end: '09:00',
            ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('MyAvailabilityNotifier.deleteSlot', () {
    test('gọi repo.deleteSlot đúng id', () async {
      final repo = _FakeAvailabilityRepo();
      final c = _container(repo);
      await c.read(myAvailabilityProvider.future);

      await c.read(myAvailabilityProvider.notifier).deleteSlot('slot7');
      expect(repo.deleteCalls, 1);
      expect(repo.lastDeletedId, 'slot7');
    });

    test('deleteSlot OK nhưng refetch lỗi → KHÔNG ném', () async {
      final repo = _FakeAvailabilityRepo(throwOnFetch: true);
      final c = _container(repo);
      await c.read(myAvailabilityProvider.future);

      await expectLater(
        c.read(myAvailabilityProvider.notifier).deleteSlot('slot7'),
        completes,
      );
    });
  });
}
