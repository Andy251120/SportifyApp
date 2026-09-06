import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../auth/application/auth_provider.dart';
import '../../profile/application/profile_provider.dart';
import '../data/match_request_model.dart';
import '../data/match_request_repository.dart';

final matchRequestRepositoryProvider = Provider<MatchRequestRepository>((ref) {
  return MatchRequestRepository(ref.watch(supabaseClientProvider));
});

/// Môn đang xem ở màn Ghép kèo. Seed từ `profiles.current_mode`; user đổi tab
/// thì `set()` — chỉ rebuild khi chính giá trị seed đổi (đổi user), không theo
/// mọi mutation hồ sơ khác (giống `ViewedSportNotifier`).
final matchmakingSportProvider =
    NotifierProvider<MatchmakingSportNotifier, String>(MatchmakingSportNotifier.new);

class MatchmakingSportNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.watch(
      myProfileProvider
          .select((a) => a.valueOrNull?.currentMode.dbValue ?? 'tennis'),
    );
  }

  void set(String sport) => state = sport;
}

/// Kèo `open` của người khác ở môn đang chọn.
final openRequestsProvider =
    AsyncNotifierProvider<OpenRequestsNotifier, List<MatchRequest>>(
        OpenRequestsNotifier.new);

class OpenRequestsNotifier extends AsyncNotifier<List<MatchRequest>> {
  MatchRequestRepository get _repo => ref.read(matchRequestRepositoryProvider);

  @override
  Future<List<MatchRequest>> build() async {
    final user = ref.watch(currentUserProvider);
    final sport = ref.watch(matchmakingSportProvider);
    if (user == null) return [];
    return _repo.fetchOpenRequests(sport);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<MatchRequest>>().copyWithPrevious(state);
    final sport = ref.read(matchmakingSportProvider);
    state = await AsyncValue.guard(() => _repo.fetchOpenRequests(sport));
  }

  /// Đăng ký tham gia kèo. Chỉ lỗi của hành động thật (`respond`) mới ném lại
  /// cho màn hình; lỗi ở bước làm mới danh sách được nuốt (lần refresh kế tiếp
  /// sẽ đồng bộ lại) — giống `MyMatchesNotifier`.
  Future<void> respond(String requestId) async {
    await _repo.respond(requestId);
    await _sync();
    ref.invalidate(requestDetailProvider(requestId));
  }

  Future<void> withdraw(String responseId) async {
    await _repo.withdrawResponse(responseId);
    await _sync();
  }

  Future<void> _sync() async {
    try {
      final sport = ref.read(matchmakingSportProvider);
      state = AsyncData(await _repo.fetchOpenRequests(sport));
    } catch (e, st) {
      debugPrint('fetchOpenRequests after action failed: $e\n$st');
    }
  }
}

/// Kèo do tôi tạo.
final myRequestsProvider =
    AsyncNotifierProvider<MyRequestsNotifier, List<MatchRequest>>(
        MyRequestsNotifier.new);

class MyRequestsNotifier extends AsyncNotifier<List<MatchRequest>> {
  MatchRequestRepository get _repo => ref.read(matchRequestRepositoryProvider);

  @override
  Future<List<MatchRequest>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return _repo.fetchMyRequests();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<MatchRequest>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_repo.fetchMyRequests);
  }

  Future<void> cancel(String id) async {
    await _repo.cancelRequest(id);
    await _sync();
    ref.invalidate(requestDetailProvider(id));
  }

  /// Chấp nhận 1 response (RPC atomic). Trả về `match_request_id`.
  Future<String> accept(String responseId) async {
    final matchRequestId = await _repo.acceptResponse(responseId);
    await _sync();
    ref.invalidate(openRequestsProvider);
    ref.invalidate(requestDetailProvider(matchRequestId));
    return matchRequestId;
  }

  Future<void> _sync() async {
    try {
      state = AsyncData(await _repo.fetchMyRequests());
    } catch (e, st) {
      debugPrint('fetchMyRequests after action failed: $e\n$st');
    }
  }
}

/// Chi tiết 1 kèo. Action nằm ở [openRequestsProvider] / [myRequestsProvider];
/// chúng tự `invalidate` provider này sau khi thành công.
final requestDetailProvider =
    FutureProvider.family<MatchRequest, String>((ref, id) async {
  ref.watch(currentUserProvider);
  return ref.watch(matchRequestRepositoryProvider).fetchRequest(id);
});

/// SĐT đối phương sau khi kèo `matched`.
final matchedContactProvider =
    FutureProvider.family<MatchedContact?, String>((ref, requestId) async {
  return ref.watch(matchRequestRepositoryProvider).matchedContact(requestId);
});
