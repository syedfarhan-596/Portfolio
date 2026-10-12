import '../core/utils/format.dart';
import '../data/models.dart';

/// Generates a handful of plain-English spending observations by comparing
/// this calendar month's confirmed expenses against last month's. Pure
/// read over existing transactions — nothing stored, nothing guessed beyond
/// what the numbers already show.
class InsightGenerator {
  static List<SpendingInsight> generate(List<Txn> confirmedTxns, Map<int, Category> categoryById) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    bool inMonth(int ms, DateTime m) {
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return d.year == m.year && d.month == m.month;
    }

    final thisMonthExpenses = confirmedTxns
        .where((t) => t.type == TxnType.expense && inMonth(t.dateTime, thisMonth))
        .toList();
    final lastMonthExpenses = confirmedTxns
        .where((t) => t.type == TxnType.expense && inMonth(t.dateTime, lastMonth))
        .toList();

    final insights = <SpendingInsight>[];
    final thisTotal = thisMonthExpenses.fold(0.0, (s, t) => s + t.amount);
    final lastTotal = lastMonthExpenses.fold(0.0, (s, t) => s + t.amount);

    if (thisMonthExpenses.isNotEmpty && lastTotal > 0) {
      final pctChange = (thisTotal - lastTotal) / lastTotal * 100;
      if (pctChange.abs() >= 5) {
        final up = pctChange > 0;
        insights.add(SpendingInsight(
          tone: up ? InsightTone.negative : InsightTone.positive,
          text: up
              ? "You've spent ${pctChange.toStringAsFixed(0)}% more this month than last "
                  '(${Money.format(thisTotal)} vs ${Money.format(lastTotal)}).'
              : "You've spent ${pctChange.abs().toStringAsFixed(0)}% less this month than "
                  'last — nice (${Money.format(thisTotal)} vs ${Money.format(lastTotal)}).',
        ));
      }
    }

    if (thisMonthExpenses.isNotEmpty && thisTotal > 0) {
      final byCat = <int?, double>{};
      for (final t in thisMonthExpenses) {
        byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
      }
      final sorted = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      final topCat = top.key != null ? categoryById[top.key] : null;
      if (topCat != null) {
        final pct = (top.value / thisTotal * 100).round();
        insights.add(SpendingInsight(
          tone: InsightTone.neutral,
          text:
              '${topCat.name} is your biggest expense this month at ${Money.format(top.value)} '
              '($pct% of total spending).',
        ));
      }
    }

    if (thisMonthExpenses.isNotEmpty && lastMonthExpenses.isNotEmpty) {
      final thisByCat = <int?, double>{};
      for (final t in thisMonthExpenses) {
        thisByCat[t.categoryId] = (thisByCat[t.categoryId] ?? 0) + t.amount;
      }
      final lastByCat = <int?, double>{};
      for (final t in lastMonthExpenses) {
        lastByCat[t.categoryId] = (lastByCat[t.categoryId] ?? 0) + t.amount;
      }

      SpendingInsight? best;
      var bestScore = 0.0;
      for (final entry in thisByCat.entries) {
        final prev = lastByCat[entry.key];
        // Ignore categories with negligible or no prior spend — a brand new
        // category "increasing by 400%" isn't a useful observation.
        if (prev == null || prev < 100) continue;
        final curr = entry.value;
        final diff = curr - prev;
        final pctChange = diff / prev * 100;
        if (pctChange.abs() < 30 || diff.abs() < 200) continue;
        final cat = entry.key != null ? categoryById[entry.key] : null;
        if (cat == null) continue;
        if (pctChange.abs() > bestScore) {
          bestScore = pctChange.abs();
          final up = diff > 0;
          best = SpendingInsight(
            tone: up ? InsightTone.negative : InsightTone.positive,
            text: up
                ? '${cat.name} spending is up ${pctChange.toStringAsFixed(0)}% from last month '
                    '(${Money.format(curr)} vs ${Money.format(prev)}).'
                : '${cat.name} spending is down ${pctChange.abs().toStringAsFixed(0)}% from last '
                    'month (${Money.format(curr)} vs ${Money.format(prev)}).',
          );
        }
      }
      if (best != null) insights.add(best);
    }

    return insights;
  }
}
