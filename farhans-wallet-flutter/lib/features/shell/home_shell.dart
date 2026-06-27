import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/glass.dart';
import '../dashboard/dashboard_screen.dart';
import '../people/people_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../reports/reports_screen.dart';
import '../transactions/add_edit_transaction_screen.dart';
import '../transactions/transactions_screen.dart';
import '../portfolio/add_investment_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _items = [
    (_NavItem(Icons.grid_view_rounded, 'Home')),
    (_NavItem(Icons.receipt_long_rounded, 'Activity')),
    (_NavItem(Icons.groups_2_rounded, 'People')),
    (_NavItem(Icons.trending_up_rounded, 'Invest')),
    (_NavItem(Icons.insights_rounded, 'Reports')),
  ];

  void _fab() {
    if (_index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInvestmentScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFab = _index == 0 || _index == 1 || _index == 3;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            DashboardScreen(),
            TransactionsScreen(),
            PeopleScreen(),
            PortfolioScreen(),
            ReportsScreen(),
          ],
        ),
      ),
      floatingActionButton: AnimatedScale(
        duration: Motion.base,
        curve: Curves.easeOutBack,
        scale: showFab ? 1 : 0,
        child: _GradientFab(onTap: _fab),
      ),
      bottomNavigationBar: _GlassNavBar(
        items: _items,
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _GradientFab extends StatelessWidget {
  final VoidCallback onTap;
  const _GradientFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: t.accentGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: t.accentB.withValues(alpha: 0.5), blurRadius: 22, offset: const Offset(0, 10)),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onTap;
  const _GlassNavBar({required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Insets.lg, 0, Insets.lg, Insets.md + MediaQuery.of(context).padding.bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Corners.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: Blurs.nav, sigmaY: Blurs.nav),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: t.glassFillStrong,
              borderRadius: BorderRadius.circular(Corners.xl),
              border: Border.all(color: t.glassBorder),
              boxShadow: t.softShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < items.length; i++)
                  _NavButton(
                    item: items[i],
                    selected: i == index,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? t.accentA.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(Corners.md),
        ),
        child: Row(
          children: [
            Icon(item.icon,
                size: 24, color: selected ? t.accentA : t.textMid),
            AnimatedSize(
              duration: Motion.base,
              curve: Curves.easeOut,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Text(item.label,
                          style: TextStyle(
                              color: t.accentA, fontWeight: FontWeight.w700, fontSize: 13)),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
