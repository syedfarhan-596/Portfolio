import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';

/// Shows what the SMS pattern-learning system has learned — trusted,
/// still-learning, or ignored templates — and lets the user reset one that
/// learned the wrong thing. Without this, a pattern wrongly marked "ignore"
/// after two accidental dismissals has no way back.
class SmsPatternsScreen extends ConsumerStatefulWidget {
  const SmsPatternsScreen({super.key});

  @override
  ConsumerState<SmsPatternsScreen> createState() => _SmsPatternsScreenState();
}

class _SmsPatternsScreenState extends ConsumerState<SmsPatternsScreen> {
  List<SmsPattern>? _patterns;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patterns = await ref.read(walletProvider.notifier).loadPatterns();
    if (mounted) setState(() => _patterns = patterns);
  }

  Future<void> _reset(SmsPattern p) async {
    await ref.read(walletProvider.notifier).resetPattern(p.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final patterns = _patterns;

    return DetailScaffold(
      title: 'SMS pattern memory',
      child: patterns == null
          ? const Center(child: CircularProgressIndicator())
          : patterns.isEmpty
              ? const EmptyState(
                  icon: Icons.psychology_alt_outlined,
                  title: 'Nothing learned yet',
                  subtitle: 'Message templates show up here the first time an SMS matching '
                      'them is captured.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.xl),
                  children: [
                    Text(
                      'Every bank/UPI message template you get is listed here once seen. '
                      'Trusted ones auto-confirm; ignored ones are treated as noise. Reset '
                      'any of them to start that template over from scratch.',
                      style: context.text.bodySmall?.copyWith(color: t.textMid),
                    ),
                    const SizedBox(height: Insets.md),
                    ...patterns.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: Insets.xs),
                          child: _PatternRow(pattern: p, onReset: () => _reset(p)),
                        )),
                  ],
                ),
    );
  }
}

class _PatternRow extends StatelessWidget {
  final SmsPattern pattern;
  final VoidCallback onReset;
  const _PatternRow({required this.pattern, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (label, color) = switch (pattern) {
      _ when pattern.alwaysIgnore => ('Ignored', t.danger),
      _ when pattern.autoConfirm => ('Trusted', t.success),
      _ => ('Learning', t.warning),
    };

    return GlassCard(
      radius: Corners.md,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pill(label: label, color: color),
                    const SizedBox(width: Insets.xs),
                    Text('seen ${pattern.timesSeen}×',
                        style: context.text.bodySmall?.copyWith(color: t.textLow)),
                  ],
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  pattern.signature,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: t.textMid,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Insets.sm),
          IconButton(
            onPressed: onReset,
            tooltip: 'Reset — forget what this learned',
            icon: Icon(Icons.restart_alt_rounded, color: t.textMid, size: 20),
          ),
        ],
      ),
    );
  }
}
