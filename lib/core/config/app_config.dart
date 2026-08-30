import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Đọc cấu hình từ .env. Gọi [AppConfig.load] trong main() trước khi dùng.
class AppConfig {
  AppConfig._();

  static String get supabaseUrl => dotenv.get('SUPABASE_URL');

  /// Publishable / anon key. Tên biến trong .env vẫn là SUPABASE_ANON_KEY.
  static String get supabaseKey => dotenv.get('SUPABASE_ANON_KEY');

  static Future<void> load() => dotenv.load(fileName: '.env');
}