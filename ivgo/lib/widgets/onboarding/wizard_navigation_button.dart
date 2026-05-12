import 'package:flutter/material.dart';

class WizardNavigationButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final int flex;
  final ButtonStyle? style;

  const WizardNavigationButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.flex = 1,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    ButtonStyle defaultStyle = filled
        ? FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size(0, 56),
          );

    Widget button = filled
        ? FilledButton(
            onPressed: onPressed,
            style: style ?? defaultStyle,
            child: Text(label),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: style ?? defaultStyle,
            child: Text(label),
          );

    return Expanded(
      flex: flex,
      child: button,
    );
  }
}
