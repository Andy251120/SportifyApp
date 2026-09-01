import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/profile_model.dart';

/// Chuyển tab Tennis / Pickleball — 2 pill bo tròn, pill active tô màu theo môn.
class SportTabSwitcher extends StatelessWidget {
  const SportTabSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SportType value;
  final ValueChanged<SportType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final sport in SportType.values)
            Expanded(
              child: _Segment(
                sport: sport,
                selected: sport == value,
                onTap: () => onChanged(sport),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.sport,
    required this.selected,
    required this.onTap,
  });

  final SportType sport;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.sportColor(sport.dbValue);
    final icon = sport == SportType.tennis
        ? Icons.sports_tennis
        : Icons.sports_handball;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 20,
                    color: selected ? Colors.white : Colors.black45),
                const SizedBox(width: 8),
                Text(
                  sport.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
