import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class CustomLineChart extends StatelessWidget {
  final List<FlSpot> data;
  final String? title;
  final String? subtitle;
  final Color? lineColor;
  final Color? fillColor;
  final double? minY;
  final double? maxY;
  final bool showGrid;
  final bool showDots;
  final double? height;

  const CustomLineChart({
    super.key,
    required this.data,
    this.title,
    this.subtitle,
    this.lineColor,
    this.fillColor,
    this.minY,
    this.maxY,
    this.showGrid = true,
    this.showDots = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 200,
      padding: const EdgeInsets.all(AppStyles.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radius12),
        boxShadow: AppStyles.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppStyles.heading6,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppStyles.spacing4),
              Text(
                subtitle!,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppStyles.spacing16),
          ],
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: showGrid
                    ? FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.grey200,
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: AppColors.grey200,
                            strokeWidth: 1,
                          );
                        },
                      )
                    : FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppStyles.caption,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppStyles.caption,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppColors.grey300,
                    width: 1,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    color: lineColor ?? AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: showDots,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: lineColor ?? AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: AppColors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (fillColor ?? AppColors.primary).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomBarChart extends StatelessWidget {
  final List<BarChartGroupData> data;
  final String? title;
  final String? subtitle;
  final Color? barColor;
  final double? maxY;
  final bool showGrid;
  final double? height;

  const CustomBarChart({
    super.key,
    required this.data,
    this.title,
    this.subtitle,
    this.barColor,
    this.maxY,
    this.showGrid = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 200,
      padding: const EdgeInsets.all(AppStyles.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radius12),
        boxShadow: AppStyles.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppStyles.heading6,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppStyles.spacing4),
              Text(
                subtitle!,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppStyles.spacing16),
          ],
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: showGrid
                    ? FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.grey200,
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: AppColors.grey200,
                            strokeWidth: 1,
                          );
                        },
                      )
                    : FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppStyles.caption,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppStyles.caption,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppColors.grey300,
                    width: 1,
                  ),
                ),
                barGroups: data,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomPieChart extends StatelessWidget {
  final List<PieChartSectionData> data;
  final String? title;
  final String? subtitle;
  final double? height;
  final double? width;
  final bool showLegends;

  const CustomPieChart({
    super.key,
    required this.data,
    this.title,
    this.subtitle,
    this.height,
    this.width,
    this.showLegends = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 300,
      width: width,
      padding: const EdgeInsets.all(AppStyles.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radius12),
        boxShadow: AppStyles.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppStyles.heading6,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppStyles.spacing4),
              Text(
                subtitle!,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppStyles.spacing16),
          ],
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: data,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                if (showLegends) ...[
                  const SizedBox(width: AppStyles.spacing16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.map((section) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppStyles.spacing4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: section.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spacing8),
                              Expanded(
                                child: Text(
                                  section.title,
                                  style: AppStyles.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomDonutChart extends StatelessWidget {
  final List<PieChartSectionData> data;
  final String? title;
  final String? subtitle;
  final String? centerText;
  final double? height;
  final double? width;
  final bool showLegends;

  const CustomDonutChart({
    super.key,
    required this.data,
    this.title,
    this.subtitle,
    this.centerText,
    this.height,
    this.width,
    this.showLegends = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 300,
      width: width,
      padding: const EdgeInsets.all(AppStyles.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radius12),
        boxShadow: AppStyles.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppStyles.heading6,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppStyles.spacing4),
              Text(
                subtitle!,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppStyles.spacing16),
          ],
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: data,
                          centerSpaceRadius: 60,
                          sectionsSpace: 2,
                        ),
                      ),
                      if (centerText != null)
                        Text(
                          centerText!,
                          style: AppStyles.heading6,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
                if (showLegends) ...[
                  const SizedBox(width: AppStyles.spacing16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.map((section) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppStyles.spacing4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: section.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spacing8),
                              Expanded(
                                child: Text(
                                  section.title,
                                  style: AppStyles.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomProgressChart extends StatelessWidget {
  final double value;
  final double maxValue;
  final String? title;
  final String? subtitle;
  final Color? color;
  final double? height;
  final bool showPercentage;

  const CustomProgressChart({
    super.key,
    required this.value,
    required this.maxValue,
    this.title,
    this.subtitle,
    this.color,
    this.height,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / maxValue * 100).clamp(0, 100);
    
    return Container(
      height: height ?? 120,
      padding: const EdgeInsets.all(AppStyles.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radius12),
        boxShadow: AppStyles.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppStyles.heading6,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppStyles.spacing4),
              Text(
                subtitle!,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppStyles.spacing16),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: AppStyles.bodyMedium,
                    ),
                    if (showPercentage)
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color ?? AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacing8),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? AppColors.primary,
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: AppStyles.spacing8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      value.toStringAsFixed(0),
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      maxValue.toStringAsFixed(0),
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
