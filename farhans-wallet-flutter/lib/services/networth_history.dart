import '../data/models.dart';
import '../data/repository.dart';

/// Reconstructs net worth at past points in time from existing transaction,
/// debt and investment records — nothing extra is stored for this; every
/// past point is recomputed the same way the live dashboard figures are,
/// just with all records after the cutoff date excluded.
///
/// Investment valuation history isn't tracked (only a live current value),
/// so past points fall back to each investment's cost basis instead of its
/// market value at that time — a reasonable approximation, not an exact
/// historical balance.
class NetWorthHistory {
  static List<NetWorthPoint> monthly({
    required List<Account> accounts,
    required List<Txn> confirmedTxns,
    required List<Investment> investments,
    required List<Debt> debts,
    int months = 6,
  }) {
    final now = DateTime.now();
    final points = <NetWorthPoint>[];
    for (var i = months - 1; i >= 0; i--) {
      final firstOfNextMonth = DateTime(now.year, now.month - i + 1, 1);
      final monthEnd = firstOfNextMonth.subtract(const Duration(milliseconds: 1));
      final cutoff = monthEnd.isAfter(now) ? now : monthEnd;
      points.add(NetWorthPoint(
        cutoff.millisecondsSinceEpoch,
        _netWorthAt(
          accounts: accounts,
          confirmedTxns: confirmedTxns,
          investments: investments,
          debts: debts,
          cutoff: cutoff,
        ),
      ));
    }
    return points;
  }

  static double _netWorthAt({
    required List<Account> accounts,
    required List<Txn> confirmedTxns,
    required List<Investment> investments,
    required List<Debt> debts,
    required DateTime cutoff,
  }) {
    final cutoffMs = cutoff.millisecondsSinceEpoch;
    final txnsUpTo = confirmedTxns.where((t) => t.dateTime <= cutoffMs).toList();

    double liquid = 0, credit = 0;
    for (final a in accounts) {
      final bal = Repository.computeBalance(a, txnsUpTo);
      if (a.type == AccountType.creditCard) {
        credit += bal;
      } else if (a.includeInTotal) {
        liquid += bal;
      }
    }

    var invested = 0.0;
    for (final inv in investments) {
      if (inv.createdAt <= cutoffMs) invested += inv.investedAmount;
    }

    var toReceive = 0.0, toPay = 0.0;
    for (final d in debts) {
      if (d.createdAt > cutoffMs) continue;
      final repaid = txnsUpTo
          .where((t) => t.debtId == d.id && t.id != d.principalTxnId)
          .fold(0.0, (s, t) => s + t.amount);
      final remaining = (d.amount - repaid).clamp(0.0, d.amount);
      if (d.direction == DebtDirection.iLent) {
        toReceive += remaining;
      } else {
        toPay += remaining;
      }
    }

    return liquid - credit + (toReceive - toPay) + invested;
  }
}
