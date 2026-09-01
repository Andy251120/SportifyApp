import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/profile_model.dart';

/// Radar chart "Show-off" — 6 trục kỹ năng từ [SkillMatrix], thang cố định 0–10.
class ShowOffRadarChart extends StatelessWidget {
  const ShowOffRadarChart({
    super.key,
    required this.matrix,
    required this.color,
    this.size = 240,
    this.showTitles = true,
  });

  final SkillMatrix matrix;
  final Color color;
  final double size;
  final bool showTitles;

  @override
  Widget build(BuildContext context) {
    final axes = matrix.axes;

    return SizedBox(
      width: size,
      height: size,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          radarBackgroundColor: Colors.transparent,
          radarBorderData: const BorderSide(color: Colors.black12),
          gridBorderData: const BorderSide(color: Colors.black12, width: 1),
          tickBorderData: const BorderSide(color: Colors.transparent),
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
          tickCount: 5,
          titlePositionPercentageOffset: 0.16,
          getTitle: showTitles
              // angle: 0 -> nhãn nằm ngang, không bị lộn ngược ở phía dưới.
              ? (index, angle) => RadarChartTitle(
                    text: axes[index % axes.length].label,
                    angle: 0,
                  )
              : (index, angle) => const RadarChartTitle(text: ''),
          titleTextStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          dataSets: [
            // Dataset ẩn cố định max = 10 để radar không tự co giãn theo dữ liệu.
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
              fillColor: color.withValues(alpha: 0.18),
              borderColor: color,
              borderWidth: 2.5,
              entryRadius: 3,
            ),
          ],
        ),
      ),
    );
  }
}
