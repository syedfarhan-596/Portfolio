import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/buttons.dart';
import '../../state/wallet_state.dart';
import '../lock/lock_gate.dart';
import 'accounts_page.dart';
import 'name_page.dart';
import 'permissions_page.dart';
import 'security_page.dart';
import 'welcome_page.dart';

/// First-run flow for a brand-new install: welcome, name, accounts,
/// permissions, security — each step skippable, ending with sensible
/// defaults either way. Shown once; see Prefs.onboardingComplete.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  static const _pageCount = 5;
  final _controller = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(duration: Motion.base, curve: Curves.easeOut);
  }

  void _back() {
    if (_page == 0) return;
    _controller.previousPage(duration: Motion.base, curve: Curves.easeOut);
  }

  void _finish() {
    final prefs = ref.read(prefsProvider);
    prefs.userName = _nameController.text.trim();
    prefs.onboardingComplete = true;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const LockGate()));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.sm, Insets.lg, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pageCount,
                      (i) => _Dot(active: i == _page),
                    ),
                  ),
                  if (_page < _pageCount - 1)
                    TextButton(
                      onPressed: _finish,
                      child: Text('Skip', style: TextStyle(color: t.textMid)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const WelcomePage(),
                  NamePage(controller: _nameController),
                  const OnboardingAccountsPage(),
                  const OnboardingPermissionsPage(),
                  const OnboardingSecurityPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, Insets.lg),
              child: Row(
                children: [
                  if (_page > 0) ...[
                    GlassIconButton(icon: Icons.arrow_back_rounded, onPressed: _back),
                    const SizedBox(width: Insets.sm),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label: _page == _pageCount - 1 ? 'Finish' : 'Continue',
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedContainer(
      duration: Motion.fast,
      margin: const EdgeInsets.only(right: 6),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? t.accentA : t.glassBorder,
        borderRadius: BorderRadius.circular(Corners.pill),
      ),
    );
  }
}
