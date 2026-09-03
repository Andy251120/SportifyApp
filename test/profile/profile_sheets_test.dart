import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/features/profile/application/profile_provider.dart';
import 'package:sport_super_app/features/profile/data/profile_model.dart';
import 'package:sport_super_app/features/profile/presentation/profile_screen.dart';

/// Notifier giả — thay build() + các method ghi để test sheet mà không cần Supabase.
class _FakeProfileNotifier extends MyProfileNotifier {
  SkillMatrix? savedSkill;
  ({String? name, String? district})? savedBasics;

  static const _sample = Profile(
    id: 'u1',
    fullName: 'Khang',
    locationDistrict: 'Hải Châu',
    stats: [
      SportStats(
        id: 's1',
        profileId: 'u1',
        sport: SportType.tennis,
        rating: 0,
        skillMatrix: SkillMatrix.filled(50),
        titles: [],
        matchesPlayed: 0,
      ),
    ],
  );

  @override
  Future<Profile?> build() async => _sample;

  @override
  Future<void> updateBasics({String? fullName, String? district}) async {
    savedBasics = (name: fullName, district: district);
  }

  @override
  Future<void> updateSkillMatrix(SportType sport, SkillMatrix matrix) async {
    savedSkill = matrix;
  }

  @override
  Future<void> uploadAvatar(Uint8List bytes, String ext) async {}
}

Widget _host(void Function(BuildContext, WidgetRef) onOpen, _FakeProfileNotifier fake) {
  return ProviderScope(
    overrides: [myProfileProvider.overrideWith(() => fake)],
    child: MaterialApp(
      home: Consumer(
        builder: (context, ref, _) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => onOpen(context, ref),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('sheet "Sửa tên / khu vực" lưu tên + quận đã chọn', (tester) async {
    final fake = _FakeProfileNotifier();
    await tester.pumpWidget(_host(showEditBasicsSheet, fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Sửa tên / khu vực'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Bảo');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sơn Trà'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(fake.savedBasics?.name, 'Bảo');
    expect(fake.savedBasics?.district, 'Sơn Trà');
  });

  testWidgets('sheet "Sửa điểm trình" lưu SkillMatrix mới (0–100)', (tester) async {
    final fake = _FakeProfileNotifier();

    await tester.pumpWidget(_host(
      (context, ref) => showEditSkillSheet(
        context,
        ref,
        SportType.tennis,
        const SkillMatrix.filled(50),
      ),
      fake,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chỉnh điểm Show-off'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(6));

    final slider = find.byType(Slider).first;
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    await tester.drag(slider, const Offset(400, 0));
    await tester.pumpAndSettle();

    final saveBtn = find.widgetWithText(ElevatedButton, 'Lưu');
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(fake.savedSkill, isNotNull);
    expect(fake.savedSkill!.spin, greaterThan(50));
    expect(fake.savedSkill!.spin, lessThanOrEqualTo(SkillMatrix.maxValue));
  });
}
