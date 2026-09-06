import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../auth/application/auth_provider.dart';
import '../../profile/application/profile_provider.dart';
import '../data/match_model.dart';
import '../data/match_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(ref.watch(supabaseClientProvider));
});

/// Mọi trận tôi liên quan (participant/official) — nguồn dữ liệu cho
/// "Trận đấu của tôi" (cần xác nhận + lịch sử gần đây).
final myMatchesProvider =
    AsyncNotifierProvider<MyMatchesNotifier, List<MatchSummary>>(MyMatchesNotifier.new);

class MyMatchesNotifier extends AsyncNotifier<List<MatchSummary>> {
  MatchRepository get _repo => ref.read(matchRepositoryProvider);

  @override
  Future<List<MatchSummary>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return _repo.fetchMyMatches();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<MatchSummary>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_repo.fetchMyMatches);
  }

  /// Xác nhận trận. Lỗi được ném lại cho màn hình hiện SnackBar — KHÔNG đẩy cả
  /// danh sách sang trạng thái error (giữ nguyên list đang hiển thị).
  Future<void> confirm(String matchId) async {
    await _repo.confirmMatch(matchId);
    // Rating vừa được rating engine cập nhật — làm mới Hồ sơ luôn.
    ref.invalidate(myProfileProvider);
    state = AsyncData(await _repo.fetchMyMatches());
  }

  Future<void> dispute(String matchId) async {
    await _repo.disputeMatch(matchId);
    state = AsyncData(await _repo.fetchMyMatches());
  }
}

/// State form "Ghi kết quả trận đấu".
class ReportMatchState {
  const ReportMatchState({
    required this.sport,
    this.matchType = MatchType.singles,
    this.partner,
    this.opponents = const [],
    this.sets = const [SetScore(a: 0, b: 0)],
    this.submitting = false,
    this.error,
  });

  final String sport;
  final MatchType matchType;
  final ProfileLite? partner;
  final List<ProfileLite> opponents;
  final List<SetScore> sets;
  final bool submitting;
  final String? error;

  int get opponentsNeeded => matchType == MatchType.singles ? 1 : 2;

  /// Có 1 bên thắng nhiều set hơn — chặn ghi trận không có kết quả rõ ràng
  /// (vd mọi set 0-0, hoặc số set thắng bằng nhau).
  bool get hasClearWinner {
    var wa = 0, wb = 0;
    for (final s in sets) {
      if (s.a > s.b) {
        wa++;
      } else if (s.b > s.a) {
        wb++;
      }
    }
    return wa != wb;
  }

  bool get canSubmit =>
      !submitting &&
      opponents.length == opponentsNeeded &&
      (matchType == MatchType.singles || partner != null) &&
      sets.isNotEmpty &&
      hasClearWinner;

  ReportMatchState copyWith({
    String? sport,
    MatchType? matchType,
    Object? partner = _sentinel,
    List<ProfileLite>? opponents,
    List<SetScore>? sets,
    bool? submitting,
    Object? error = _sentinel,
  }) {
    return ReportMatchState(
      sport: sport ?? this.sport,
      matchType: matchType ?? this.matchType,
      partner: identical(partner, _sentinel) ? this.partner : partner as ProfileLite?,
      opponents: opponents ?? this.opponents,
      sets: sets ?? this.sets,
      submitting: submitting ?? this.submitting,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

final reportMatchControllerProvider =
    NotifierProvider.autoDispose<ReportMatchController, ReportMatchState>(
        ReportMatchController.new);

class ReportMatchController extends AutoDisposeNotifier<ReportMatchState> {
  @override
  ReportMatchState build() {
    final sport = ref.watch(myProfileProvider).valueOrNull?.currentMode.dbValue ?? 'tennis';
    return ReportMatchState(sport: sport);
  }

  void setSport(String sport) => state = state.copyWith(sport: sport);

  void setMatchType(MatchType type) {
    state = state.copyWith(
      matchType: type,
      partner: type == MatchType.singles ? null : state.partner,
      opponents: const [],
    );
  }

  void setPartner(ProfileLite? p) => state = state.copyWith(partner: p);

  void addOpponent(ProfileLite p) {
    if (state.opponents.length >= state.opponentsNeeded) return;
    if (state.opponents.any((o) => o.id == p.id)) return;
    state = state.copyWith(opponents: [...state.opponents, p]);
  }

  void removeOpponent(String id) {
    state = state.copyWith(opponents: state.opponents.where((o) => o.id != id).toList());
  }

  void addSet() {
    if (state.sets.length >= 5) return;
    state = state.copyWith(sets: [...state.sets, const SetScore(a: 0, b: 0)]);
  }

  void removeSet(int index) {
    final next = [...state.sets]..removeAt(index);
    if (next.isEmpty) return;
    state = state.copyWith(sets: next);
  }

  void updateSet(int index, {int? a, int? b}) {
    final current = state.sets[index];
    final next = [...state.sets];
    next[index] = SetScore(a: a ?? current.a, b: b ?? current.b);
    state = state.copyWith(sets: next);
  }

  /// Trả về true nếu tạo trận thành công.
  Future<bool> submit(String myId) async {
    if (!state.canSubmit) return false;
    state = state.copyWith(submitting: true, error: null);
    try {
      final sideA = [myId, if (state.partner != null) state.partner!.id];
      final sideB = state.opponents.map((o) => o.id).toList();
      await ref.read(matchRepositoryProvider).createMatch(
            sport: state.sport,
            matchType: state.matchType,
            sideAIds: sideA,
            sideBIds: sideB,
            score: state.sets,
          );
      state = state.copyWith(submitting: false);
      ref.invalidate(myMatchesProvider);
      return true;
    } catch (e, st) {
      debugPrint('createMatch failed: $e\n$st');
      state = state.copyWith(
        submitting: false,
        error: 'Ghi kết quả chưa được, bạn thử lại chút nha!',
      );
      return false;
    }
  }
}
