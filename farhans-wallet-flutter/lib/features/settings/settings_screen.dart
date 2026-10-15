import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/glass.dart';
import '../../services/prefs.dart';
import '../../state/wallet_state.dart';
import '../budgets/budgets_screen.dart';
import '../goals/savings_goals_screen.dart';
import '../insights/subscriptions_screen.dart';
import '../lock/app_lock_screen.dart';
import '../lock/pin_setup_screen.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import 'sms_patterns_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    ref.read(lockServiceProvider).canUseBiometrics().then((v) {
      if (mounted) setState(() => _biometricAvailable = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final prefs = ref.read(prefsProvider);

    return DetailScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.xl),
        children: [
          _profileCard(context, prefs),
          const SizedBox(height: Insets.sm),
          // App lock
          GlassCard(
            child: Column(
              children: [
                _row(
                  Icons.lock_rounded,
                  t.danger,
                  'App lock',
                  'Require a PIN to open Pocket Flow',
                  Switch(
                    value: prefs.appLockEnabled,
                    activeThumbColor: t.accentA,
                    onChanged: (v) async {
                      if (v) {
                        final ok = await Navigator.push<bool>(context,
                            MaterialPageRoute(builder: (_) => const PinSetupScreen()));
                        if (ok == true) setState(() {});
                      } else {
                        setState(() {
                          prefs.appLockEnabled = false;
                          ref.read(lockServiceProvider).clearPin(prefs);
                        });
                      }
                    },
                  ),
                ),
                if (prefs.appLockEnabled) ...[
                  const SizedBox(height: Insets.sm),
                  Pressable(
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const PinSetupScreen())),
                    child: Row(
                      children: [
                        Icon(Icons.pin_rounded, color: t.accentA),
                        const SizedBox(width: Insets.xs),
                        Text('Change PIN',
                            style: TextStyle(color: t.accentA, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (_biometricAvailable) ...[
                    const SizedBox(height: Insets.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Also allow fingerprint/face unlock',
                              style: context.text.bodyMedium),
                        ),
                        Switch(
                          value: prefs.biometricEnabled,
                          activeThumbColor: t.accentA,
                          onChanged: (v) => setState(() => prefs.biometricEnabled = v),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: Insets.sm),
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
                  'Transactions are added automatically when a bank/UPI SMS arrives',
                  Switch(
                    value: prefs.smsCapture,
                    activeThumbColor: t.accentA,
                    onChanged: (v) => setState(() => prefs.smsCapture = v),
                  ),
                ),
                if (prefs.smsCapture && !prefs.smsPermGranted) ...[
                  const SizedBox(height: Insets.sm),
                  Container(
                    padding: const EdgeInsets.all(Insets.sm),
                    decoration: BoxDecoration(
                      color: t.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Corners.sm),
                      border: Border.all(color: t.danger.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: t.danger, size: 20),
                        const SizedBox(width: Insets.xs),
                        Expanded(
                          child: Text(
                            'SMS permission isn\'t granted, so nothing is being captured. '
                            'Tap "Check for new SMS now" below to re-request it, or enable it '
                            'manually in Android Settings → Apps → Pocket Flow → Permissions.',
                            style: context.text.bodySmall?.copyWith(color: t.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Insets.sm),
                Pressable(
                  onTap: () async {
                    final sms = ref.read(smsServiceProvider);
                    final granted = await sms.requestPermission();
                    setState(() => prefs.smsPermGranted = granted);
                    if (!granted) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('SMS permission is needed to read transactions')));
                      return;
                    }
                    await ref.read(walletProvider.notifier).scanNewSms();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Checked for new transactions')));
                  },
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, color: t.accentA),
                      const SizedBox(width: Insets.xs),
                      Text('Check for new SMS now',
                          style: TextStyle(color: t.accentA, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  'New message templates are added as pending for you to confirm or correct '
                  'once; after a few consistent confirmations, that template auto-confirms on '
                  'its own going forward. Dismissing a message enough times teaches the app to '
                  'ignore it outright (useful for promotional texts that slip through). Only '
                  'messages received after installing are captured.',
                  style: context.text.bodySmall?.copyWith(color: t.textMid),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.sm),
          _backupCard(context),
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
          _navCard(Icons.psychology_alt_rounded, t.success, 'SMS pattern memory',
              'See what\'s trusted or ignored, and reset any of it', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SmsPatternsScreen()));
          }),
          const SizedBox(height: Insets.sm),
          _navCard(Icons.autorenew_rounded, t.info, 'Subscriptions & recurring',
              'Charges that repeat on their own, spotted automatically', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen()));
          }),
          const SizedBox(height: Insets.sm),
          _navCard(Icons.pie_chart_rounded, t.warning, 'Budgets',
              'Set a monthly cap per category and track against it', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()));
          }),
          const SizedBox(height: Insets.sm),
          _navCard(Icons.savings_rounded, t.success, 'Savings goals',
              'Set a target and track how close you are to it', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()));
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
                  'All your data is stored locally — nothing is uploaded to any server. '
                  'Uninstalling removes the local copy, so keep an exported backup if you want to restore later.',
                  style: context.text.bodyMedium?.copyWith(color: t.textMid),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          Center(
            child: Text(appVersionLabel,
                style: context.text.bodySmall?.copyWith(color: t.textLow)),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(BuildContext context, Prefs prefs) {
    final t = context.tokens;
    final name = prefs.userName;
    return GlassCard(
      onTap: () => _editName(context, prefs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: t.accentA.withValues(alpha: 0.2),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(color: t.accentA, fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'Add your name' : name, style: context.text.titleSmall),
                Text('Shown as your greeting on Home',
                    style: context.text.bodySmall?.copyWith(color: t.textMid)),
              ],
            ),
          ),
          Icon(Icons.edit_rounded, color: t.textMid, size: 20),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, Prefs prefs) async {
    final controller = TextEditingController(text: prefs.userName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.tokens.bgBottom,
        title: const Text('Your name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null) setState(() => prefs.userName = name);
  }

  Widget _backupCard(BuildContext context) {
    final t = context.tokens;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(Icons.cloud_sync_rounded, t.info, 'Backup & restore', null, null),
          const SizedBox(height: Insets.sm),
          Container(
            padding: const EdgeInsets.all(Insets.sm),
            decoration: BoxDecoration(
              color: t.glassFill,
              borderRadius: BorderRadius.circular(Corners.sm),
              border: Border.all(color: t.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Move your data to another phone', style: context.text.titleSmall),
                const SizedBox(height: 6),
                _step(context, '1', 'Tap Export below and save the backup file (to Drive, WhatsApp, Files…).'),
                _step(context, '2', 'Install Pocket Flow on the other phone.'),
                _step(context, '3', 'There, open Settings → Backup & restore → Import and pick that file.'),
                const SizedBox(height: 6),
                Text(
                  'Tip: export now and then so a backup exists before you ever uninstall — '
                  'the app also opts into Android auto-backup, but an exported file is the sure way.',
                  style: context.text.bodySmall?.copyWith(color: t.textMid),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Export',
                  icon: Icons.ios_share_rounded,
                  onPressed: () async {
                    final data = await ref.read(walletProvider.notifier).exportData();
                    await ref.read(backupServiceProvider).exportAndShare(data);
                  },
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: SecondaryButton(
                  label: 'Import',
                  icon: Icons.download_rounded,
                  onPressed: () => _import(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          SecondaryButton(
            label: 'Export transactions as CSV',
            icon: Icons.table_chart_rounded,
            onPressed: () async {
              final rows = ref.read(walletProvider).value?.transactionCsvRows();
              if (rows == null) return;
              await ref.read(backupServiceProvider).exportTransactionsCsv(rows);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final data = await ref.read(backupServiceProvider).pickAndRead();
    if (data == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.tokens.bgBottom,
        title: const Text('Restore from backup?'),
        content: const Text(
            'This replaces all current data in Pocket Flow with the contents of the backup file. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(walletProvider.notifier).importData(data);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Data restored successfully')));
  }

  Widget _step(BuildContext context, String n, String text) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.accentA.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Text(n, style: TextStyle(color: t.accentA, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: Insets.xs),
          Expanded(child: Text(text, style: context.text.bodySmall?.copyWith(color: t.textMid))),
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
