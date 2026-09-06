import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/friendly_empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/rounded_card.dart';
import '../application/availability_provider.dart';
import '../data/availability_model.dart';

/// "Khung giờ rảnh" — vào từ menu Hồ sơ. Nhóm slot theo môn, thêm/xoá slot.
class AvailabilityEditorScreen extends ConsumerWidget {
  const AvailabilityEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAvailabilityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Khung giờ rảnh')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => FriendlyEmptyState(
          emoji: '📡',
          title: 'Không tải được',
          message: 'Mạng chập chờn, thử lại nhé!',
          action: PrimaryButton(
            label: 'Thử lại',
            onPressed: () =>
                ref.read(myAvailabilityProvider.notifier).refresh(),
          ),
        ),
        data: (slots) => RefreshIndicator(
          onRefresh: () =>
              ref.read(myAvailabilityProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (slots.isEmpty)
                const FriendlyEmptyState(
                  emoji: '📅',
                  title: 'Chưa đặt khung giờ nào',
                  message:
                      'Chưa đặt khung giờ nào. Thêm để bạn bè biết khi nào rủ bạn được!',
                )
              else
                for (final sport in const ['tennis', 'pickleball'])
                  if (slots.any((s) => s.sport == sport)) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        sport == 'tennis' ? 'Tennis' : 'Pickleball',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.sportColor(sport),
                        ),
                      ),
                    ),
                    for (final s in slots.where((s) => s.sport == sport))
                      _SlotTile(slot: s),
                  ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Thêm khung giờ'),
                onPressed: () => _openAddSheet(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: _AddSlotSheet(
          onAdd: (sport, day, start, end) =>
              ref.read(myAvailabilityProvider.notifier).addSlot(
                    sport: sport,
                    dayOfWeek: day,
                    start: start,
                    end: end,
                  ),
        ),
      ),
    );
  }
}

class _SlotTile extends ConsumerWidget {
  const _SlotTile({required this.slot});
  final AvailabilitySlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RoundedCard(
        child: Row(
          children: [
            Expanded(
              child: Text('${slot.dayLabel} · ${slot.rangeLabel}',
                  style: const TextStyle(fontSize: 15)),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Xoá khung giờ',
              onPressed: () async {
                try {
                  await ref
                      .read(myAvailabilityProvider.notifier)
                      .deleteSlot(slot.id);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(
                          content: Text('Xoá chưa được, thử lại nha!')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Validate khoảng giờ — tách ra để test được không cần dựng widget.
@visibleForTesting
bool availabilityRangeValid(TimeOfDay? start, TimeOfDay? end) {
  if (start == null || end == null) return false;
  return start.hour * 60 + start.minute < end.hour * 60 + end.minute;
}

String _fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class _AddSlotSheet extends StatefulWidget {
  const _AddSlotSheet({required this.onAdd});

  final Future<void> Function(
      String sport, int dayOfWeek, String start, String end) onAdd;

  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  String _sport = 'tennis';
  int _day = 0;
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _saving = false;

  bool get _valid => availabilityRangeValid(_start, _end);

  Future<void> _pick({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _start : _end) ??
          TimeOfDay(hour: isStart ? 8 : 10, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onAdd(_sport, _day, _fmtTime(_start!), _fmtTime(_end!));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('Thêm chưa được, thử lại nha!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Thêm khung giờ rảnh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          const Text('Môn', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in const ['tennis', 'pickleball'])
                ChoiceChip(
                  label: Text(s == 'tennis' ? 'Tennis' : 'Pickleball'),
                  selected: _sport == s,
                  selectedColor:
                      AppTheme.sportColor(s).withValues(alpha: 0.18),
                  onSelected: (_) => setState(() => _sport = s),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Ngày', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < kDayLabels.length; i++)
                ChoiceChip(
                  label: Text(kDayLabels[i]),
                  selected: _day == i,
                  onSelected: (_) => setState(() => _day = i),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(isStart: true),
                  child: Text(
                      _start == null ? 'Giờ bắt đầu' : _fmtTime(_start!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(isStart: false),
                  child:
                      Text(_end == null ? 'Giờ kết thúc' : _fmtTime(_end!)),
                ),
              ),
            ],
          ),
          if (_start != null && _end != null && !_valid) ...[
            const SizedBox(height: 8),
            const Text('Giờ kết thúc phải sau giờ bắt đầu nha.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Lưu',
            loading: _saving,
            onPressed: (!_valid || _saving) ? null : _save,
          ),
        ],
      ),
    );
  }
}
