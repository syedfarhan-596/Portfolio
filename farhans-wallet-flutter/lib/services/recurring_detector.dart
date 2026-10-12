import '../data/models.dart';

/// Detects recurring/subscription-like spending by grouping confirmed
/// transactions that share a merchant, account and type, then checking
/// whether they repeat at a roughly constant interval and amount. Purely a
/// read over existing transaction history — no new data entry, no network
/// calls, nothing persisted.
class RecurringDetector {
  static const _dayMs = 86400000;

  static List<RecurringSeries> detect(List<Txn> confirmedTxns) {
    final groups = <String, List<Txn>>{};
    for (final t in confirmedTxns) {
      final merchant = t.merchant.trim();
      if (merchant.isEmpty) continue;
      final key = '${merchant.toLowerCase()}|${t.accountId}|${t.type.name}';
      groups.putIfAbsent(key, () => []).add(t);
    }

    final results = <RecurringSeries>[];
    for (final list in groups.values) {
      if (list.length < 2) continue;
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      final gaps = <int>[];
      for (var i = 1; i < list.length; i++) {
        gaps.add(((list[i].dateTime - list[i - 1].dateTime) / _dayMs).round());
      }
      final cadence = _classify(gaps);
      if (cadence == null) continue;

      final amounts = list.map((t) => t.amount).toList();
      final avg = amounts.reduce((a, b) => a + b) / amounts.length;
      if (avg == 0) continue;
      final variance =
          amounts.map((a) => (a - avg) * (a - avg)).reduce((a, b) => a + b) / amounts.length;
      final coefficientOfVariation = variance > 0 ? (variance / (avg * avg)) : 0.0;
      // Amounts bouncing around too wildly aren't a believable subscription.
      if (coefficientOfVariation > 0.3) continue;

      final last = list.last;
      final categoryCounts = <int?, int>{};
      for (final t in list) {
        categoryCounts[t.categoryId] = (categoryCounts[t.categoryId] ?? 0) + 1;
      }
      final topCategory = categoryCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

      results.add(RecurringSeries(
        merchant: last.merchant.trim(),
        accountId: last.accountId,
        categoryId: topCategory,
        type: last.type,
        cadence: cadence,
        occurrenceCount: list.length,
        averageAmount: avg,
        lastAmount: last.amount,
        lastDate: last.dateTime,
        nextExpectedDate: last.dateTime + cadence.days * _dayMs,
      ));
    }

    results.sort((a, b) => a.nextExpectedDate.compareTo(b.nextExpectedDate));
    return results;
  }

  /// A cadence is confirmed only when every gap between consecutive
  /// occurrences falls in the same tolerance band — a single stray gap (a
  /// skipped month, an early renewal) disqualifies it rather than being
  /// averaged away into a false pattern.
  static RecurringCadence? _classify(List<int> gaps) {
    bool within(int g, int lo, int hi) => g >= lo && g <= hi;
    if (gaps.every((g) => within(g, 6, 8))) return RecurringCadence.weekly;
    if (gaps.every((g) => within(g, 27, 33))) return RecurringCadence.monthly;
    if (gaps.every((g) => within(g, 350, 380))) return RecurringCadence.yearly;
    return null;
  }
}
