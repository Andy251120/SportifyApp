import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/match_provider.dart';
import '../data/match_model.dart';

/// Ô tìm người chơi theo tên (debounce nhẹ) — chạm kết quả để chọn.
/// Dùng cho chọn đối thủ / đồng đội ở màn ghi kết quả.
class PlayerPickerField extends ConsumerStatefulWidget {
  const PlayerPickerField({
    super.key,
    required this.hintText,
    required this.onPicked,
    this.excludeIds = const [],
  });

  final String hintText;
  final ValueChanged<ProfileLite> onPicked;
  final List<String> excludeIds;

  @override
  ConsumerState<PlayerPickerField> createState() => _PlayerPickerFieldState();
}

class _PlayerPickerFieldState extends ConsumerState<PlayerPickerField> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<ProfileLite> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final found = await ref.read(matchRepositoryProvider).searchPlayers(query);
      if (!mounted) return;
      setState(() {
        _results = found.where((p) => !widget.excludeIds.contains(p.id)).toList();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in _results)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.courtGreen.withValues(alpha: 0.15),
                      backgroundImage: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                      child: p.avatarUrl == null
                          ? Text(p.displayName.substring(0, 1).toUpperCase())
                          : null,
                    ),
                    title: Text(p.displayName),
                    onTap: () {
                      widget.onPicked(p);
                      _ctrl.clear();
                      setState(() => _results = []);
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Chip nhỏ hiện người đã chọn, có nút bỏ chọn.
class PickedPlayerChip extends StatelessWidget {
  const PickedPlayerChip({super.key, required this.player, required this.onRemove});

  final ProfileLite player;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: AppTheme.courtGreen.withValues(alpha: 0.15),
        backgroundImage: player.avatarUrl != null ? NetworkImage(player.avatarUrl!) : null,
        child: player.avatarUrl == null
            ? Text(player.displayName.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 11))
            : null,
      ),
      label: Text(player.displayName),
      onDeleted: onRemove,
    );
  }
}
