import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/core/widgets/friendly_empty_state.dart';
import 'package:sport_super_app/core/widgets/primary_button.dart';
import 'package:sport_super_app/features/auth/data/auth_repository.dart';

void main() {
  group('normalizeVietnamPhone', () {
    test('0-prefixed -> +84', () {
      expect(AuthRepository.normalizeVietnamPhone('0912 345 678'), '+84912345678');
    });
    test('84-prefixed -> +84', () {
      expect(AuthRepository.normalizeVietnamPhone('84912345678'), '+84912345678');
    });
    test('already E.164 unchanged', () {
      expect(AuthRepository.normalizeVietnamPhone('+84912345678'), '+84912345678');
    });
  });

  testWidgets('PrimaryButton shows spinner and blocks tap while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PrimaryButton(label: 'Gửi mã', loading: true, onPressed: () => taps++),
      ),
    ));

    expect(find.text('Gửi mã'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(PrimaryButton));
    expect(taps, 0);
  });

  testWidgets('FriendlyEmptyState renders friendly copy', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FriendlyEmptyState(
          emoji: '🎾',
          title: 'Ghép kèo',
          message: 'Chưa có ai rủ chơi hôm nay, đăng lời mời đi bạn ơi!',
        ),
      ),
    ));

    expect(find.text('Ghép kèo'), findsOneWidget);
    expect(find.textContaining('đăng lời mời đi bạn ơi'), findsOneWidget);
  });
}
