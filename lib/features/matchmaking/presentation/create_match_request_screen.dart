import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/rounded_card.dart';
import '../application/match_request_provider.dart';
import 'matchmaking_ui.dart';

/// "Đăng kèo mới" — form tối giản: môn + ngày (tùy chọn) + lời nhắn (tùy chọn).
class CreateMatchRequestScreen extends ConsumerStatefulWidget {
  const CreateMatchRequestScreen({super.key});

  @override
  ConsumerState<CreateMatchRequestScreen> createState() =>
      _CreateMatchRequestScreenState();
}

class _CreateMatchRequestScreenState
    extends ConsumerState<CreateMatchRequestScreen> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createMatchRequestControllerProvider);
    final controller = ref.read(createMatchRequestControllerProvider.notifier);

    ref.listen(createMatchRequestControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng kèo mới')),
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
                        for (final s in const ['tennis', 'pickleball'])
                          ChoiceChip(
                            label: Text(sportLabel(s)),
                            selected: state.sport == s,
                            selectedColor: AppTheme.sportColor(s)
                                .withValues(alpha: 0.18),
                            onSelected: (_) => controller.setSport(s),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _Label('Hôm nào?'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              state.preferredDate == null
                                  ? 'Chọn ngày (không bắt buộc)'
                                  : prettyRequestDate(state.preferredDate),
                            ),
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: state.preferredDate ?? now,
                                firstDate:
                                    DateTime(now.year, now.month, now.day),
                                lastDate: now.add(const Duration(days: 60)),
                              );
                              if (picked != null) controller.setDate(picked);
                            },
                          ),
                        ),
                        if (state.preferredDate != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Bỏ ngày',
                            onPressed: () => controller.setDate(null),
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
                    const _Label('Lời nhắn'),
                    const SizedBox(height: 8),
                    _NoteField(controller: _noteController),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Đăng kèo',
                icon: Icons.send,
                loading: state.submitting,
                onPressed: state.submitting
                    ? null
                    : () async {
                        final ok = await controller.submit(
                            note: _noteController.text);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(
                              content: Text(
                                  'Đã đăng kèo! Chờ người xin vào nhé.'),
                            ));
                          Navigator.of(context).maybePop();
                        }
                      },
              ),
              const SizedBox(height: 8),
              const Text(
                'Kèo sẽ hiện ở "Kèo đang mở" cho người chơi cùng môn. Ai xin vào'
                ' thì bạn chọn một người để ghép nhé.',
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

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: const InputDecoration(
        hintText:
            'Nhắn gì đó: tìm bạn đánh đôi tối nay, trình vui vẻ...',
      ),
    );
  }
}
