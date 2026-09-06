import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../auth/application/auth_provider.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

/// Hồ sơ của user hiện tại. `null` khi chưa đăng nhập.
/// Là nguồn sự thật duy nhất cho router (onboarding gate) và tab Hồ sơ.
final myProfileProvider =
    AsyncNotifierProvider<MyProfileNotifier, Profile?>(MyProfileNotifier.new);

class MyProfileNotifier extends AsyncNotifier<Profile?> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  Future<Profile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return _repo.fetchMyProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Profile?>().copyWithPrevious(state);
    state = await AsyncValue.guard(_repo.fetchMyProfile);
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading<Profile?>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await action();
      return _repo.fetchMyProfile();
    });
  }

  Future<void> completeOnboarding({
    required String fullName,
    required String district,
    required List<SportType> sports,
    required Map<SportType, SkillMatrix> ratings,
  }) {
    return _run(() => _repo.completeOnboarding(
          fullName: fullName,
          district: district,
          sports: sports,
          ratings: ratings,
        ));
  }

  Future<void> updateSkillMatrix(SportType sport, SkillMatrix matrix) {
    return _run(() => _repo.updateSkillMatrix(sport, matrix));
  }

  Future<void> addSport(SportType sport, SkillMatrix matrix) {
    return _run(() => _repo.addSport(sport, matrix));
  }

  Future<void> updateBasics({String? fullName, String? district}) {
    return _run(() => _repo.updateBasics(fullName: fullName, district: district));
  }

  Future<void> uploadAvatar(Uint8List bytes, String ext) {
    return _run(() => _repo.uploadAvatar(bytes, ext));
  }

  /// Đổi tab môn đang xem — optimistic, không loading toàn màn.
  Future<void> setViewedSport(SportType sport) async {
    final current = state.valueOrNull;
    if (current != null && current.currentMode != sport) {
      state = AsyncData(_copyWithMode(current, sport));
    }
    try {
      await _repo.setCurrentMode(sport);
    } catch (_) {
      // Không critical — lần fetch sau sẽ đồng bộ lại.
    }
  }

  Profile _copyWithMode(Profile p, SportType mode) => Profile(
        id: p.id,
        fullName: p.fullName,
        avatarUrl: p.avatarUrl,
        coverUrl: p.coverUrl,
        locationDistrict: p.locationDistrict,
        trustScore: p.trustScore,
        currentMode: mode,
        isVerified: p.isVerified,
        updatedAt: p.updatedAt,
        stats: p.stats,
      );
}

/// Môn đang xem ở tab Hồ sơ. Seed từ `profiles.current_mode`.
final viewedSportProvider =
    NotifierProvider<ViewedSportNotifier, SportType>(ViewedSportNotifier.new);

class ViewedSportNotifier extends Notifier<SportType> {
  @override
  SportType build() {
    // Seed từ `current_mode` — chỉ rebuild khi chính giá trị này đổi (đổi user,
    // hoặc user tự chọn tab), KHÔNG rebuild theo mọi mutation hồ sơ khác.
    return ref.watch(
      myProfileProvider
          .select((a) => a.valueOrNull?.currentMode ?? SportType.tennis),
    );
  }

  void set(SportType sport) {
    state = sport;
    ref.read(myProfileProvider.notifier).setViewedSport(sport);
  }
}
