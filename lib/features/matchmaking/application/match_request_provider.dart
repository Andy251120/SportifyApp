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
    ref.invalidate(respondedRequestsProvider);
  }

  Future<void> withdraw(String responseId) async {
    await _repo.withdrawResponse(responseId);
    await _sync();
    ref.invalidate(respondedRequestsProvider);
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
    ref.invalidate(respondedRequestsProvider);
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

/// Mọi kèo tôi đã "xin vào" — mọi trạng thái response + mọi trạng thái kèo.
/// Không có mutation ở đây: respond/withdraw xảy ra qua [openRequestsProvider],
/// accept qua [myRequestsProvider]; chúng tự `invalidate` provider này.
final respondedRequestsProvider =
    AsyncNotifierProvider<RespondedRequestsNotifier, List<MatchRequest>>(
        RespondedRequestsNotifier.new);

class RespondedRequestsNotifier extends AsyncNotifier<List<MatchRequest>> {
  MatchRequestRepository get _repo => ref.read(matchRequestRepositoryProvider);

  @override
  Future<List<MatchRequest>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return _repo.fetchRespondedRequests();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<MatchRequest>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_repo.fetchRespondedRequests);
  }
}

/// Section "Kèo tôi đã xin vào" chỉ giữ kèo còn ý nghĩa để tôi xem:
/// - response `accepted` → luôn giữ (xem SĐT đối phương).
/// - response `declined` + kèo KHÔNG còn `open` → chủ kèo chọn người khác /
///   huỷ kèo → giữ (chip "Chủ kèo chọn người khác rồi" đúng ngữ cảnh).
///
/// Loại bỏ:
/// - response `pending` → kèo phải còn `open` → đã hiện ở "Kèo đang mở" (kèm
///   nút Rút) → tránh trùng.
/// - response `declined` + kèo vẫn `open` → suy ra tôi tự rút → ẩn.
List<MatchRequest> visibleRespondedRequests(
  List<MatchRequest> all,
  String myId,
) {
  return all.where((r) {
    final status = r.myResponse(myId)?.status;
    if (status == ResponseStatus.accepted) return true;
    return status == ResponseStatus.declined &&
        r.status != MatchRequestStatus.open;
  }).toList();
}

/// Chi tiết 1 kèo. Action nằm ở [openRequestsProvider] / [myRequestsProvider];
/// chúng tự `invalidate` provider này sau khi thành công.
final requestDetailProvider =
    FutureProvider.autoDispose.family<MatchRequest, String>((ref, id) async {
  ref.watch(currentUserProvider);
  return ref.watch(matchRequestRepositoryProvider).fetchRequest(id);
});

/// SĐT đối phương sau khi kèo `matched`.
final matchedContactProvider = FutureProvider.autoDispose
    .family<MatchedContact?, String>((ref, requestId) async {
  ref.watch(currentUserProvider);
  return ref.watch(matchRequestRepositoryProvider).matchedContact(requestId);
});

/// State form "Đăng kèo mới" — tối giản: môn + ngày (tùy chọn) + lời nhắn.
class CreateMatchRequestState {
  const CreateMatchRequestState({
    required this.sport,
    this.preferredDate,
    this.note = '',
    this.submitting = false,
    this.error,
  });

  final String sport; // 'tennis' | 'pickleball'
  final DateTime? preferredDate;
  final String note;
  final bool submitting;
  final String? error;

  CreateMatchRequestState copyWith({
    String? sport,
    Object? preferredDate = _sentinel,
    String? note,
    bool? submitting,
    Object? error = _sentinel,
  }) {
    return CreateMatchRequestState(
      sport: sport ?? this.sport,
      preferredDate: identical(preferredDate, _sentinel)
          ? this.preferredDate
          : preferredDate as DateTime?,
      note: note ?? this.note,
      submitting: submitting ?? this.submitting,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

final createMatchRequestControllerProvider = NotifierProvider.autoDispose<
    CreateMatchRequestController, CreateMatchRequestState>(
    CreateMatchRequestController.new);

class CreateMatchRequestController
    extends AutoDisposeNotifier<CreateMatchRequestState> {
  @override
  CreateMatchRequestState build() {
    final sport = ref.watch(matchmakingSportProvider);
    return CreateMatchRequestState(sport: sport);
  }

  void setSport(String sport) => state = state.copyWith(sport: sport);

  void setDate(DateTime? date) => state = state.copyWith(preferredDate: date);

  void setNote(String note) => state = state.copyWith(note: note);

  /// Trả về true nếu đăng kèo thành công. [note] (nếu truyền) được set 1 lần
  /// ngay trước submit — màn hình giữ `TextEditingController` riêng, không
  /// gọi [setNote] mỗi keystroke.
  Future<bool> submit({String? note}) async {
    if (state.submitting) return false;
    if (note != null) state = state.copyWith(note: note);
    state = state.copyWith(submitting: true, error: null);
    try {
      final trimmed = state.note.trim();
      await ref.read(matchRequestRepositoryProvider).createRequest(
            sport: state.sport,
            preferredDate: state.preferredDate,
            note: trimmed.isEmpty ? null : trimmed,
          );
      state = state.copyWith(submitting: false);
      ref.invalidate(myRequestsProvider);
      return true;
    } catch (e, st) {
      debugPrint('createRequest failed: $e\n$st');
      state = state.copyWith(
        submitting: false,
        error: 'Đăng kèo chưa được, bạn thử lại chút nha!',
      );
      return false;
    }
  }
}
