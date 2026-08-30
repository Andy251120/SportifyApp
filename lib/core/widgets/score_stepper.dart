import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bộ đếm +/- để nhập tỷ số bằng 1 tay, không gõ số (dùng từ Phase 2).
/// Đặt sẵn ở Phase 0 như một khối UI dùng chung.
class ScoreStepper extends StatelessWidget {
  const ScoreStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.label,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove,
              onTap: value > min ? () => onChanged(value - 1) : null,
            ),
            Container(
              width: 64,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              onTap: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Material(
      color: onTap == null ? Colors.grey.shade200 : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        child: SizedBox(
          height: 52,
          width: 52,
          child: Icon(icon, color: onTap == null ? Colors.grey : color, size: 28),
        ),
      ),
    );
  }
}
