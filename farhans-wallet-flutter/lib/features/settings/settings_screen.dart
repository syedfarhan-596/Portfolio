import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final prefs = ref.read(prefsProvider);
    final data = ref.watch(walletProvider).value;
    final accounts = data?.accounts ?? [];

    return DetailScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.xl),
        children: [
          // Daily reminder
          GlassCard(
            child: Column(
              children: [
                _row(
                  Icons.notifications_active_rounded,
                  t.accentA,
                  'Daily reminder',
                  'Nudge me every night to log expenses',
                  Switch(
                    value: prefs.reminderEnabled,
                    activeThumbColor: t.accentA,
                    onChanged: (v) async {
                      setState(() => prefs.reminderEnabled = v);
                      final notif = ref.read(notificationProvider);
                      if (v) {
                        await notif.requestPermission();
                        await notif.scheduleDaily(prefs.reminderHour, prefs.reminderMinute);
                      } else {
                        await notif.cancelReminder();
                      }
                    },
                  ),
                ),
                if (prefs.reminderEnabled) ...[
                  const SizedBox(height: Insets.xs),
                  Pressable(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: prefs.reminderHour, minute: prefs.reminderMinute),
                      );
                      if (picked != null) {
                        setState(() {
                          prefs.reminderHour = picked.hour;
                          prefs.reminderMinute = picked.minute;
                        });
                        await ref.read(notificationProvider).scheduleDaily(picked.hour, picked.minute);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reminder time', style: context.text.bodyLarge),
                        Text(
                          '${prefs.reminderHour.toString().padLeft(2, '0')}:${prefs.reminderMinute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: t.accentA, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Insets.sm),
          // SMS capture
          GlassCard(
            child: Column(
              children: [
                _row(
                  Icons.sms_rounded,
                  t.success,
                  'Auto-capture from SMS',
                  'Detect UPI / bank transactions automatically',
                  Switch(
                    value: prefs.smsCapture,
                    activeThumbColor: t.accentA,
                    onChanged: (v) => setState(() => prefs.smsCapture = v),
                  ),
                ),
                const SizedBox(height: Insets.sm),
                Pressable(
                  onTap: () async {
                    final count = await ref.read(walletProvider.notifier).importSmsInbox();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(count < 0
                          ? 'SMS permission needed to read transactions'
                          : 'Imported $count transactions from SMS'),
                    ));
                  },
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, color: t.accentA),
                      const SizedBox(width: Insets.xs),
                      Text('Scan SMS inbox now',
                          style: TextStyle(color: t.accentA, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.sm),
          // Default UPI account
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(Icons.account_balance_wallet_rounded, t.info,
                    'Default account for detected UPI', null, null),
                const SizedBox(height: Insets.sm),
                AppSelectField<Account>(
                  label: 'Account',
                  value: accounts.where((a) => a.id == prefs.defaultUpiAccountId).firstOrNull,
                  options: accounts,
                  optionLabel: (a) => a.name,
                  onChanged: (a) => setState(() => prefs.defaultUpiAccountId = a.id ?? -1),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.sm),
          _navCard(Icons.account_balance_rounded, t.warning, 'Manage accounts',
              'Banks, cash & cards', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen()));
          }),
          const SizedBox(height: Insets.sm),
          _navCard(Icons.category_rounded, t.accentA, 'Manage categories',
              'Customize expense & income types', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()));
          }),
          const SizedBox(height: Insets.sm),
          // Theme
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(Icons.palette_rounded, t.textHigh, 'Appearance', null, null),
                const SizedBox(height: Insets.sm),
                AppSelectField<ThemeMode>(
                  label: 'Theme',
                  value: ref.watch(themeModeProvider),
                  options: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
                  optionLabel: (m) => switch (m) {
                    ThemeMode.system => 'System',
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                  },
                  onChanged: (m) {
                    ref.read(themeModeProvider.notifier).state = m;
                    prefs.themeMode = switch (m) {
                      ThemeMode.light => 1,
                      ThemeMode.system => 0,
                      ThemeMode.dark => 2,
                    };
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.sm),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔒 100% on your device', style: context.text.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'All your data is stored locally in this app. Nothing is uploaded to any server.',
                  style: context.text.bodyMedium?.copyWith(color: t.textMid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, Color color, String title, String? subtitle, Widget? trailing) {
    final t = context.tokens;
    return Row(
      children: [
        IconBadge(icon: icon, color: color),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleSmall),
              if (subtitle != null)
                Text(subtitle, style: context.text.bodySmall?.copyWith(color: t.textMid)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _navCard(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) {
    final t = context.tokens;
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: icon, color: color),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(subtitle, style: context.text.bodySmall?.copyWith(color: t.textMid)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: t.textMid),
        ],
      ),
    );
  }
}
