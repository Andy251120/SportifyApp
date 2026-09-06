import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/features/auth/presentation/onboarding_screen.dart';
import 'package:sport_super_app/features/profile/application/profile_provider.dart';
import 'package:sport_super_app/features/profile/data/profile_model.dart';

/// Notifier giả — bắt tham số completeOnboarding, không đụng Supabase.
class _FakeProfileNotifier extends MyProfileNotifier {
  ({
    String fullName,
    String district,
    List<SportType> sports,
    Map<SportType, SkillMatrix> ratings,
  })? captured;

  @override
  Future<Profile?> build() async => null;

  @override
  Future<void> completeOnboarding({
    required String fullName,
    required String district,
    required List<SportType> sports,
    required Map<SportType, SkillMatrix> ratings,
  }) async {
    captured = (
      fullName: fullName,
      district: district,
      sports: sports,
      ratings: ratings,
    );
  }
}

Widget _host(_FakeProfileNotifier fake) => ProviderScope(
      overrides: [myProfileProvider.overrideWith(() => fake)],
      child: const MaterialApp(home: OnboardingScreen()),
    );

void main() {
  testWidgets('bước tên: "Tiếp tục" khoá tới khi tên đủ 2 ký tự', (tester) async {
    await tester.pumpWidget(_host(_FakeProfileNotifier()));
    await tester.pumpAndSettle();

    ElevatedButton nextBtn() =>
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Tiếp tục'));
    expect(nextBtn().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'A');
    await tester.pump();
    expect(nextBtn().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Khang');
    await tester.pump();
    expect(nextBtn().onPressed, isNotNull);
  });

  testWidgets('đi hết 3 bước rồi submit đúng tên/quận/môn', (tester) async {
    final fake = _FakeProfileNotifier();
    await tester.pumpWidget(_host(fake));
    await tester.pumpAndSettle();

    // Bước 1 — tên
    await tester.enterText(find.byType(TextField), 'Khang');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tiếp tục'));
    await tester.pumpAndSettle();

    // Bước 2 — quận + môn
    expect(find.text('Bạn ở đâu, chơi gì?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tiếp tục')); // vẫn khoá
    await tester.pumpAndSettle();
    expect(find.text('Bạn ở đâu, chơi gì?'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Hải Châu'));
    await tester.tap(find.text('Tennis'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tiếp tục'));
    await tester.pumpAndSettle();

    // Bước 3 — tự chấm điểm → submit
    expect(find.text('Tự chấm điểm trình'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Vô sân thôi!'));
    // Sau submit widget kẹt ở trạng thái loading (thực tế router điều hướng đi),
    // nên pump vài nhịp thay vì pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fake.captured, isNotNull);
    expect(fake.captured!.fullName, 'Khang');
    expect(fake.captured!.district, 'Hải Châu');
    expect(fake.captured!.sports, [SportType.tennis]);
    expect(fake.captured!.ratings[SportType.tennis], isNotNull);
  });
}
