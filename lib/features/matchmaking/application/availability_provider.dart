import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../auth/application/auth_provider.dart';
import '../data/availability_model.dart';
import '../data/availability_repository.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  return AvailabilityRepository(ref.watch(supabaseClientProvider));
});

/// Khung giờ rảnh của tôi.
final myAvailabilityProvider =
    AsyncNotifierProvider<MyAvailabilityNotifier, List<AvailabilitySlot>>(
        MyAvailabilityNotifier.new);

class MyAvailabilityNotifier extends AsyncNotifier<List<AvailabilitySlot>> {
  AvailabilityRepository get _repo => ref.read(availabilityRepositoryProvider);

  @override
  Future<List<AvailabilitySlot>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return _repo.fetchMyAvailability();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<AvailabilitySlot>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_repo.fetchMyAvailability);
  }

  /// Thêm khung giờ. Lỗi hành động thật (`addSlot`) ném lại cho màn hình;
  /// lỗi refetch được nuốt.
  Future<void> addSlot({
    required String sport,
    required int dayOfWeek,
    required String start,
    required String end,
  }) async {
    await _repo.addSlot(
      sport: sport,
      dayOfWeek: dayOfWeek,
      start: start,
      end: end,
    );
    await _sync();
  }

  Future<void> deleteSlot(String id) async {
    await _repo.deleteSlot(id);
    await _sync();
  }

  Future<void> _sync() async {
    try {
      state = AsyncData(await _repo.fetchMyAvailability());
    } catch (e, st) {
      debugPrint('fetchMyAvailability after action failed: $e\n$st');
    }
  }
}

/// Khung giờ rảnh của 1 user ở 1 môn — cho màn chi tiết kèo. Tham số:
/// `(profileId, sport)`.
final availabilityForProvider = FutureProvider.family<List<AvailabilitySlot>,
    (String, String)>((ref, args) async {
  return ref
      .watch(availabilityRepositoryProvider)
      .fetchAvailabilityFor(args.$1, args.$2);
});
