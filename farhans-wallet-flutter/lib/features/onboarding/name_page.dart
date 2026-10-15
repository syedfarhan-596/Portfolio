import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fields.dart';

class NamePage extends StatelessWidget {
  final TextEditingController controller;
  const NamePage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What should we call you?', style: context.text.headlineSmall),
          const SizedBox(height: Insets.xs),
          Text(
            'Just for a personal touch — this stays on your phone like everything else.',
            style: context.text.bodyMedium?.copyWith(color: t.textMid),
          ),
          const SizedBox(height: Insets.lg),
          AppTextField(label: 'Your name', controller: controller),
        ],
      ),
    );
  }
}
