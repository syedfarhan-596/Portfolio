import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'buttons.dart';

/// Shared layout for push screens: transparent scaffold over the global
/// background, with a glass back button, title and optional trailing action.
class DetailScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? bottomBar;
  const DetailScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Insets.md, Insets.sm, Insets.md, Insets.xs),
              child: Row(
                children: [
                  GlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(child: Text(title, style: context.text.titleLarge)),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Expanded(child: child),
            if (bottomBar != null)
              Padding(
                padding: EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg,
                    Insets.md + MediaQuery.of(context).padding.bottom),
                child: bottomBar!,
              ),
          ],
        ),
      ),
    );
  }
}
