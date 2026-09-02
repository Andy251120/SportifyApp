import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('bước nhập SĐT: nút "Nhận mã OTP" + dòng phụ tạo hồ sơ',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LoginScreen()),
    ));
    await tester.pump();

    expect(find.text('Nhận mã OTP'), findsOneWidget);
    expect(
      find.textContaining('Đăng nhập lần đầu sẽ tự tạo hồ sơ'),
      findsOneWidget,
    );
    expect(find.text('Vào sân chơi thôi!'), findsOneWidget);
  });
}
