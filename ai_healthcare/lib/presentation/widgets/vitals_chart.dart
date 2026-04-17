import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/colors.dart';

class VitalsChart extends StatelessWidget {
  final List<dynamic> metrics;
  final String type;
  final Color color;

  const VitalsChart({
    super.key,
    required this.metrics,
    required this.type,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filter and sort metrics for this type
    final filtered = metrics
        .where((m) => m['metric_type'] == type)
        .toList();
    
    filtered.sort((a, b) {
      final da = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
      final db = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
      return da.compareTo(db);
    });

    if (filtered.length < 2) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withAlpha(5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('Not enough data for trend analysis', style: TextStyle(fontSize: 12, color: Colors.grey))),
      );
    }

    // Limit to last 7 points for clarity
    final recent = filtered.length > 7 ? filtered.sublist(filtered.length - 7) : filtered;

    final spots = recent.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble());
    }).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withAlpha(150) : Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= recent.length) return const SizedBox();
                  final dt = DateTime.tryParse(recent[value.toInt()]['timestamp'] ?? '') ?? DateTime.now();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${dt.day}/${dt.month}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(colors: [color, color.withAlpha(150)]),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: color,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withAlpha(50), color.withAlpha(0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
