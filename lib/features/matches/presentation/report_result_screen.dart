import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Môn', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final sport in ['tennis', 'pickleball'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(sport == 'tennis' ? 'Tennis' : 'Pickleball'),
                        selected: state.sport == sport,
                        onSelected: (_) => controller.setSport(sport),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Loại trận', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final type in MatchType.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(type.label),
                        selected: state.matchType == type,
                        onSelected: (_) => controller.setMatchType(type),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Đội của bạn', style: TextStyle(fontWeight: FontWeight.bold)),
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
              if (state.matchType == MatchType.doubles && state.partner == null) ...[
                const SizedBox(height: 8),
                PlayerPickerField(
                  hintText: 'Tìm đồng đội theo tên',
                  excludeIds: [if (myId != null) myId, ...state.opponents.map((o) => o.id)],
                  onPicked: controller.setPartner,
                ),
              ],
              const SizedBox(height: 20),
              const Text('Đối thủ', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 20),
              const Text('Tỷ số', style: TextStyle(fontWeight: FontWeight.bold)),
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
