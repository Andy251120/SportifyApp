import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/core/theme/app_theme.dart';
import 'package:sport_super_app/features/profile/data/profile_model.dart';
import 'package:sport_super_app/features/profile/presentation/sport_tab_switcher.dart';

void main() {
  testWidgets('hiện 2 tab và bắn onChanged khi chạm', (tester) async {
    SportType? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SportTabSwitcher(
          value: SportType.tennis,
          onChanged: (s) => picked = s,
        ),
      ),
    ));

    expect(find.text('Tennis'), findsOneWidget);
    expect(find.text('Pickleball'), findsOneWidget);

    await tester.tap(find.text('Pickleball'));
    expect(picked, SportType.pickleball);
  });

  testWidgets('tab đang chọn tô màu theo môn', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SportTabSwitcher(
          value: SportType.pickleball,
          onChanged: _noop,
        ),
      ),
    ));

    final selected = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text('Pickleball'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = selected.decoration! as BoxDecoration;
    expect(decoration.color, AppTheme.sportColor('pickleball'));
  });
}

void _noop(SportType _) {}
