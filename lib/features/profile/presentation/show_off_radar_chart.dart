import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/profile_model.dart';

/// Radar chart "Show-off" — 6 trục kỹ năng từ [SkillMatrix], thang cố định 0–100.
/// Caller tự set chiều cao (UI_SPEC: 220px).
class ShowOffRadarChart extends StatelessWidget {
  const ShowOffRadarChart({
    super.key,
    required this.matrix,
    required this.color,
    this.showTitles = true,
  });

  final SkillMatrix matrix;
  final Color color;
  final bool showTitles;

  @override
  Widget build(BuildContext context) {
    final axes = matrix.axes;

    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        radarBackgroundColor: Colors.transparent,
        radarBorderData: const BorderSide(color: AppTheme.borderSubtle),
        gridBorderData: const BorderSide(color: AppTheme.borderSubtle, width: 1),
        tickBorderData: const BorderSide(color: Colors.transparent),
        ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 8),
        tickCount: 4, // 25 / 50 / 75 / 100
        titlePositionPercentageOffset: 0.16,
        getTitle: showTitles
            // angle: 0 -> nhãn nằm ngang, không bị lộn ngược ở phía dưới.
            ? (index, angle) => RadarChartTitle(
                  text: axes[index % axes.length].label,
                  angle: 0,
                )
            : (index, angle) => const RadarChartTitle(text: ''),
        titleTextStyle: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        dataSets: [
          // Dataset ẩn cố định max = 100 để radar không tự co giãn theo dữ liệu.
          RadarDataSet(
            dataEntries: [
              for (var i = 0; i < axes.length; i++)
                const RadarEntry(value: SkillMatrix.maxValue),
            ],
            fillColor: Colors.transparent,
            borderColor: Colors.transparent,
            borderWidth: 0,
            entryRadius: 0,
          ),
          RadarDataSet(
            dataEntries: [
              for (final a in axes) RadarEntry(value: a.value),
            ],
            fillColor: color.withValues(alpha: 0.2),
            borderColor: color,
            borderWidth: 2,
            entryRadius: 2.5,
          ),
        ],
      ),
    );
  }
}
