import 'package:flutter/material.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/widgets/timer_card_base.dart';

class InfusionRow extends StatelessWidget {
  final InfusionTimer timer;
  final void Function(InfusionTimer theTimer)? onRemove;
  final void Function(InfusionTimer theTimer)? onEdit;
  final void Function(InfusionTimer theTimer)? onChanged;

  const InfusionRow(this.timer, {super.key, this.onRemove, this.onEdit, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isRecoveredOverdue = timer.isRecoveredOverdue;

    return TimerCardBase(
      timer: timer,
      trailingWidget: _ActionMenuButton(
        tooltip: 'More Actions',
        foregroundColor: isRecoveredOverdue ? colorScheme.onErrorContainer : colorScheme.onSurface,
        backgroundColor: isRecoveredOverdue ? colorScheme.error.withValues(alpha: 0.08) : colorScheme.surface,
        onSelected: (_InfusionRowAction action) {
          switch (action) {
            case _InfusionRowAction.acknowledge:
              timer.acknowledgeRecoveredOverdue();
              if (onChanged != null) {
                onChanged!(timer);
              }
            case _InfusionRowAction.edit:
              if (onEdit != null) {
                onEdit!(timer);
              }
            case _InfusionRowAction.toggleRunning:
              if (timer.isRunning) {
                timer.stop();
              } else {
                timer.start();
              }
              if (onChanged != null) {
                onChanged!(timer);
              }
            case _InfusionRowAction.reset:
              timer.reset();
              if (onChanged != null) {
                onChanged!(timer);
              }
            case _InfusionRowAction.remove:
              _showRemoveConfirmation(context);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_InfusionRowAction>>[
          if (isRecoveredOverdue)
            const PopupMenuItem<_InfusionRowAction>(
              value: _InfusionRowAction.acknowledge,
              child: _ActionMenuItemContent(
                icon: Icons.check_circle_outline,
                label: 'Acknowledge',
              ),
            ),
          const PopupMenuItem<_InfusionRowAction>(
            value: _InfusionRowAction.edit,
            child: _ActionMenuItemContent(
              icon: Icons.edit_outlined,
              label: 'Edit',
            ),
          ),
          if (!timer.isEnded)
            PopupMenuItem<_InfusionRowAction>(
              value: _InfusionRowAction.toggleRunning,
              child: _ActionMenuItemContent(
                icon: timer.isRunning ? Icons.pause : Icons.play_arrow,
                label: timer.isRunning ? 'Pause' : 'Resume',
              ),
            ),
          const PopupMenuItem<_InfusionRowAction>(
            value: _InfusionRowAction.reset,
            child: _ActionMenuItemContent(
              icon: Icons.refresh,
              label: 'Reset',
            ),
          ),
          PopupMenuItem<_InfusionRowAction>(
            value: _InfusionRowAction.remove,
            child: Row(
              children: <Widget>[
                Icon(Icons.delete_outlined, size: 20, color: colorScheme.error),
                const SizedBox(width: 10),
                Text(
                  'Remove',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Removal'),
          content: const Text('Are you sure you want to remove this infusion?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () {
                Navigator.of(context).pop();

                if (onRemove != null) {
                  onRemove!(timer);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

enum _InfusionRowAction {
  acknowledge,
  edit,
  toggleRunning,
  reset,
  remove,
}

class _ActionMenuButton extends StatelessWidget {
  const _ActionMenuButton({
    required this.tooltip,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.itemBuilder,
    required this.onSelected,
  });

  final String tooltip;
  final Color foregroundColor;
  final Color backgroundColor;
  final PopupMenuItemBuilder<_InfusionRowAction> itemBuilder;
  final PopupMenuItemSelected<_InfusionRowAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: PopupMenuButton<_InfusionRowAction>(
        tooltip: tooltip,
        padding: const EdgeInsets.all(12),
        icon: Icon(Icons.more_vert, color: foregroundColor),
        itemBuilder: itemBuilder,
        onSelected: onSelected,
      ),
    );
  }
}

class _ActionMenuItemContent extends StatelessWidget {
  const _ActionMenuItemContent({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: colorScheme.onSurface),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
