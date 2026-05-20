import 'package:flutter/material.dart';

class WizardPageIndicator extends StatelessWidget {
  const WizardPageIndicator({
    super.key,
    required this.isActive,
    required this.context,
  });

  final bool isActive;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
