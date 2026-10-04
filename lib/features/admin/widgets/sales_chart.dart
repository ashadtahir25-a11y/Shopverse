import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/surface_card.dart';
import '../providers/admin_sales_chart_provider.dart';

const _monthAbbr = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class SalesChartCard extends ConsumerWidget {
  const SalesChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(salesChartRangeProvider);
    final dataAsync = ref.watch(salesChartDataProvider);

    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppDimens.md,
              runSpacing: AppDimens.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Sales Trend', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ChartRange.values.map((r) {
                    final selected = r == range;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(r.label),
                        selected: selected,
                        onSelected: (_) => ref.read(salesChartRangeProvider.notifier).state = r,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: AppTextStyles.caption.copyWith(
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.lg),
            SizedBox(
              height: 220,
              child: dataAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Couldn\u2019t load sales data', style: AppTextStyles.bodyMedium)),
                data: (days) => _Chart(days: days),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final List<DailySales> days;
  const _Chart({required this.days});

  @override
  Widget build(BuildContext context) {
    if (days.every((d) => d.total == 0)) {
      return Center(
        child: Text('No sales yet in this period', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      );
    }

    final maxY = days.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    // A little headroom above the tallest point so the line/dot isn't
    // clipped against the top edge of the chart.
    final topPadding = maxY <= 0 ? 100.0 : maxY * 0.2;
    final isWeekView = days.length <= 7;
    // Thin out x-axis labels on the 30-day view so they don't overlap —
    // showing every ~5th day is still enough to read the trend.
    final labelInterval = isWeekView ? 1 : (days.length / 6).ceil();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY + topPadding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY + topPadding) / 4,
          getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: (maxY + topPadding) / 4 == 0 ? 1 : (maxY + topPadding) / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                final label = value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0);
                return Text(label, style: AppTextStyles.caption);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length || i % labelInterval != 0) return const SizedBox.shrink();
                final d = days[i].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${d.day} ${_monthAbbr[d.month]}', style: AppTextStyles.caption),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final d = days[spot.x.toInt()].date;
              return LineTooltipItem(
                'Rs. ${spot.y.toStringAsFixed(0)}\n${d.day} ${_monthAbbr[d.month]}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < days.length; i++) FlSpot(i.toDouble(), days[i].total)],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.22), AppColors.primary.withValues(alpha: 0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}