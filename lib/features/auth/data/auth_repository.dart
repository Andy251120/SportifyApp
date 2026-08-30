import 'package:supabase_flutter/supabase_flutter.dart';

/// Lớp duy nhất được phép gọi Supabase Auth trực tiếp.
/// Luồng đăng nhập: nhập số điện thoại -> nhận OTP SMS -> xác thực OTP.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  /// Chuẩn hoá số điện thoại VN về dạng E.164 (+84...).
  /// "0912345678" -> "+84912345678", "84912345678" -> "+84912345678".
  static String normalizeVietnamPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('0')) return '+84${digits.substring(1)}';
    if (digits.startsWith('84')) return '+$digits';
    return '+84$digits';
  }

  /// Gửi mã OTP tới số điện thoại (đã chuẩn hoá E.164).
  Future<void> sendPhoneOtp(String phoneE164) {
    return _client.auth.signInWithOtp(phone: phoneE164);
  }

  /// Xác thực mã OTP. Trả về true nếu đây là lần đăng nhập đầu tiên
  /// (vừa tạo mới row profiles).
  Future<bool> verifyPhoneOtp({
    required String phoneE164,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phoneE164,
      token: token,
    );
    return _ensureProfileRow();
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Tạo 1 row profiles cơ bản (id = auth user id) nếu chưa tồn tại.
  /// Các cột còn lại để mặc định / null — onboarding chọn môn + tự đánh giá
  /// điểm trình là việc của Phase 1.
  Future<bool> _ensureProfileRow() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) return false;

    await _client.from('profiles').insert({'id': user.id});
    return true;
  }
}
