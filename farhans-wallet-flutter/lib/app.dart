import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/app_background.dart';
import 'features/shell/home_shell.dart';
import 'state/wallet_state.dart';

class FarhansWalletApp extends ConsumerWidget {
  const FarhansWalletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: "Farhan's Wallet",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      builder: (context, child) => AppBackground(child: child ?? const SizedBox()),
      home: const HomeShell(),
    );
  }
}
