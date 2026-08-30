import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// User hiện tại (null nếu chưa đăng nhập). Cập nhật theo sự kiện auth.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});

enum LoginStep { enterPhone, enterOtp }

class LoginState {
  const LoginState({
    this.step = LoginStep.enterPhone,
    this.phoneE164 = '',
    this.submitting = false,
    this.error,
    this.justCreatedProfile = false,
  });

  final LoginStep step;
  final String phoneE164;
  final bool submitting;
  final String? error;
  final bool justCreatedProfile;

  LoginState copyWith({
    LoginStep? step,
    String? phoneE164,
    bool? submitting,
    Object? error = _sentinel,
    bool? justCreatedProfile,
  }) {
    return LoginState(
      step: step ?? this.step,
      phoneE164: phoneE164 ?? this.phoneE164,
      submitting: submitting ?? this.submitting,
      error: identical(error, _sentinel) ? this.error : error as String?,
      justCreatedProfile: justCreatedProfile ?? this.justCreatedProfile,
    );
  }

  static const _sentinel = Object();
}

class LoginController extends AutoDisposeNotifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Gửi OTP. [rawPhone] là số người dùng gõ (có thể có 0 đầu, dấu cách...).
  Future<void> sendOtp(String rawPhone) async {
    final phone = AuthRepository.normalizeVietnamPhone(rawPhone);
    if (phone.length < 11) {
      state = state.copyWith(error: 'Số điện thoại chưa đúng rồi, bạn kiểm tra lại nhé!');
      return;
    }

    state = state.copyWith(submitting: true, error: null, phoneE164: phone);
    try {
      await _repo.sendPhoneOtp(phone);
      state = state.copyWith(step: LoginStep.enterOtp, submitting: false);
    } on AuthException catch (e) {
      state = state.copyWith(submitting: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        submitting: false,
        error: 'Gửi mã không được, thử lại sau chút nha!',
      );
    }
  }

  Future<void> verifyOtp(String token) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      final created = await _repo.verifyPhoneOtp(
        phoneE164: state.phoneE164,
        token: token.trim(),
      );
      state = state.copyWith(submitting: false, justCreatedProfile: created);
    } on AuthException catch (e) {
      state = state.copyWith(submitting: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        submitting: false,
        error: 'Mã chưa đúng hoặc đã hết hạn, bạn thử lại nhé!',
      );
    }
  }

  void backToPhone() {
    state = state.copyWith(step: LoginStep.enterPhone, error: null);
  }
}

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(LoginController.new);
