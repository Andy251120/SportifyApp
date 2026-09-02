import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/features/profile/data/profile_model.dart';
import 'package:sport_super_app/features/profile/presentation/skill_rating_editor.dart';

void main() {
  testWidgets('kéo slider bắn SkillMatrix mới (thang 0–100)', (tester) async {
    var current = const SkillMatrix.filled(50);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 800,
          child: SingleChildScrollView(
            child: SkillRatingEditor(
              value: current,
              color: Colors.orange,
              showPreview: false,
              onChanged: (m) => current = m,
            ),
          ),
        ),
      ),
    ));

    // 6 slider cho 6 trục.
    expect(find.byType(Slider), findsNWidgets(6));

    final firstSlider = find.byType(Slider).first;
    await tester.drag(firstSlider, const Offset(300, 0));
    await tester.pump();

    // Trục đầu (spin) tăng lên, các trục khác giữ nguyên 50.
    expect(current.spin, greaterThan(50));
    expect(current.power, 50);
    expect(current.spin, lessThanOrEqualTo(SkillMatrix.maxValue));
  });
}
