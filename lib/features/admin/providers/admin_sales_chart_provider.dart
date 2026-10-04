import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ChartRange { last7Days, last30Days }

extension ChartRangeX on ChartRange {
  int get days => this == ChartRange.last7Days ? 7 : 30;
  String get label => this == ChartRange.last7Days ? '7 Days' : '30 Days';
}

class DailySales {
  final DateTime date;
  final double total;
  final int orderCount;

  const DailySales({required this.date, required this.total, required this.orderCount});
}

/// Which range the Dashboard's chart is currently showing — a plain
/// local UI toggle, not persisted.
final salesChartRangeProvider = StateProvider<ChartRange>((ref) => ChartRange.last7Days);

String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// Aggregates the `orders` collection into one total-per-day for the
/// selected range, seeding every day (including days with zero orders)
/// so the chart always shows a continuous line instead of gaps.
///
/// Reads the whole collection client-side and aggregates in Dart —
/// fine at this scale, same approach as admin_stats_provider.dart. If
/// the order volume grows large, a Cloud Function that maintains a
/// pre-aggregated `dailySales/{date}` document on each order write
/// would be the next step (avoids re-reading every order just to
/// redraw the chart).
final salesChartDataProvider = StreamProvider.autoDispose<List<DailySales>>((ref) {
  final range = ref.watch(salesChartRangeProvider);
  final days = range.days;

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startDate = startOfToday.subtract(Duration(days: days - 1));

  return FirebaseFirestore.instance.collection('orders').snapshots().map((snapshot) {
    final totals = <String, double>{};
    final counts = <String, int>{};
    for (var i = 0; i < days; i++) {
      final key = _dateKey(startDate.add(Duration(days: i)));
      totals[key] = 0;
      counts[key] = 0;
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final dateStr = data['date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final dayOnly = DateTime(date.year, date.month, date.day);
      if (dayOnly.isBefore(startDate)) continue;

      final key = _dateKey(dayOnly);
      if (!totals.containsKey(key)) continue;

      final total = (data['total'] as num?)?.toDouble() ?? 0;
      totals[key] = (totals[key] ?? 0) + total;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    return List.generate(days, (i) {
      final d = startDate.add(Duration(days: i));
      final key = _dateKey(d);
      return DailySales(date: d, total: totals[key] ?? 0, orderCount: counts[key] ?? 0);
    });
  });
});