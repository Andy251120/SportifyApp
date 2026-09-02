import 'package:flutter/material.dart';

import '../data/profile_model.dart';
import 'show_off_radar_chart.dart';

/// 6 slider tự chấm (0–10) + radar preview cập nhật live.
/// Dùng chung cho onboarding bước 3 và sheet "Chỉnh điểm" ở màn Hồ sơ.
class SkillRatingEditor extends StatelessWidget {
  const SkillRatingEditor({
    super.key,
    required this.value,
    required this.onChanged,
    required this.color,
    this.showPreview = true,
  });

  final SkillMatrix value;
  final ValueChanged<SkillMatrix> onChanged;
  final Color color;
  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPreview) ...[
          SizedBox(
            height: 220,
            child: ShowOffRadarChart(matrix: value, color: color),
          ),
          const SizedBox(height: 8),
        ],
        for (final axis in value.axes)
          _SliderRow(
            label: axis.label,
            value: axis.value,
            color: color,
            onChanged: (v) => onChanged(value.withAxis(axis.key, v)),
          ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: value.clamp(0, SkillMatrix.maxValue),
                max: SkillMatrix.maxValue,
                divisions: 20, // bước nhảy 5
                label: value.toStringAsFixed(0),
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              value.toStringAsFixed(0),
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
