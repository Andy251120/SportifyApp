import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/profile_model.dart';

/// Chuyển tab Tennis / Pickleball (UI_SPEC mục 2).
/// Nền [AppTheme.surfaceMuted] bo 16, 2 phần bằng nhau; tab chọn tô
/// [AppTheme.sportColor] chữ trắng, tab không chọn trong suốt chữ xám.
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
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppTheme.sportColor(sport.dbValue) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              sport.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
