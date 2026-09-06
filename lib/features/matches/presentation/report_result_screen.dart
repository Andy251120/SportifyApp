import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/rounded_card.dart';
import '../../../core/widgets/score_stepper.dart';
import '../../auth/application/auth_provider.dart';
import '../application/match_provider.dart';
import '../data/match_model.dart';
import 'player_picker_field.dart';

/// Ghi kết quả trận đấu — chọn môn/loại trận, chọn đối thủ (và đồng đội nếu
/// đánh đôi), nhập tỷ số từng set bằng ScoreStepper, gửi qua RPC create_match.
class ReportResultScreen extends ConsumerWidget {
  const ReportResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportMatchControllerProvider);
    final controller = ref.read(reportMatchControllerProvider.notifier);
    final myId = ref.watch(currentUserProvider)?.id;
    final sportColor = AppTheme.sportColor(state.sport);

    ref.listen(reportMatchControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Ghi kết quả trận đấu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoundedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Môn'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final sport in ['tennis', 'pickleball'])
                          ChoiceChip(
                            label: Text(sport == 'tennis' ? 'Tennis' : 'Pickleball'),
                            selected: state.sport == sport,
                            selectedColor:
                                AppTheme.sportColor(sport).withValues(alpha: 0.18),
                            onSelected: (_) => controller.setSport(sport),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _Label('Loại trận'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final type in MatchType.values)
                          ChoiceChip(
                            label: Text(type.label),
                            selected: state.matchType == type,
                            selectedColor: sportColor.withValues(alpha: 0.18),
                            onSelected: (_) => controller.setMatchType(type),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              RoundedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Đội của bạn'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Chip(label: Text('Bạn')),
                        if (state.partner != null)
                          PickedPlayerChip(
                            player: state.partner!,
                            onRemove: () => controller.setPartner(null),
                          ),
                      ],
                    ),
                    if (state.matchType == MatchType.doubles &&
                        state.partner == null) ...[
                      const SizedBox(height: 8),
                      PlayerPickerField(
                        hintText: 'Tìm đồng đội theo tên',
                        excludeIds: [
                          if (myId != null) myId,
                          ...state.opponents.map((o) => o.id),
                        ],
                        onPicked: controller.setPartner,
                      ),
                    ],
                    const SizedBox(height: 16),
                    const _Label('Đối thủ'),
                    const SizedBox(height: 8),
                    if (state.opponents.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final o in state.opponents)
                            PickedPlayerChip(
                              player: o,
                              onRemove: () => controller.removeOpponent(o.id),
                            ),
                        ],
                      ),
                    if (state.opponents.length < state.opponentsNeeded) ...[
                      const SizedBox(height: 8),
                      PlayerPickerField(
                        hintText: state.matchType == MatchType.singles
                            ? 'Tìm đối thủ theo tên'
                            : 'Tìm thêm đối thủ theo tên',
                        excludeIds: [
                          if (myId != null) myId,
                          if (state.partner != null) state.partner!.id,
                          ...state.opponents.map((o) => o.id),
                        ],
                        onPicked: controller.addOpponent,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              RoundedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Tỷ số'),
                    const SizedBox(height: 8),
                    for (var i = 0; i < state.sets.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ScoreStepper(
                              label: 'Đội bạn',
                              value: state.sets[i].a,
                              max: 20,
                              onChanged: (v) => controller.updateSet(i, a: v),
                            ),
                            ScoreStepper(
                              label: 'Đối thủ',
                              value: state.sets[i].b,
                              max: 20,
                              onChanged: (v) => controller.updateSet(i, b: v),
                            ),
                            if (state.sets.length > 1)
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => controller.removeSet(i),
                              ),
                          ],
                        ),
                      ),
                    if (state.sets.length < 5)
                      TextButton.icon(
                        onPressed: controller.addSet,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm set'),
                      ),
                    if (!state.hasClearWinner)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Nhập tỷ số sao cho một bên thắng nhiều set hơn nha.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Ghi kết quả',
                icon: Icons.check_circle_outline,
                loading: state.submitting,
                onPressed: state.canSubmit && myId != null
                    ? () async {
                        final ok = await controller.submit(myId);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(
                              content: Text(
                                  'Đã ghi nhận! Chờ đối thủ xác nhận trong 24h nha.'),
                            ));
                          Navigator.of(context).maybePop();
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Đối thủ xác nhận thì điểm trình mới cập nhật. Không ai xác nhận thì'
                ' sau 24h hệ thống tự xác nhận giúp bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold));
  }
}
