import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ivgo/domain/infusion_timer.dart';

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
    final String remainingTime = _formatRemainingTime(timer.remainingSeconds);
    final double progress = timer.characteristics.volume <= 0 ? 0 : (timer.infusedVolume / timer.characteristics.volume).clamp(0.0, 1.0);
    final Color progressColor;
    final Color cardColor;
    final Color borderColor;
    final Color contentColor;
    final Color mutedColor;
    final String statusLabel;
    final IconData statusIcon;
    final Color statusBackgroundColor;
    final Color statusForegroundColor;

    if (isRecoveredOverdue) {
      progressColor = colorScheme.error;
      cardColor = colorScheme.errorContainer;
      borderColor = colorScheme.error;
      contentColor = colorScheme.onErrorContainer;
      mutedColor = colorScheme.onErrorContainer;
      statusLabel = 'Review';
      statusIcon = Icons.warning_amber_rounded;
      statusBackgroundColor = colorScheme.error;
      statusForegroundColor = colorScheme.onError;
    } else if (timer.isEnded) {
      progressColor = colorScheme.outline;
      cardColor = colorScheme.surfaceContainerLow;
      borderColor = colorScheme.outlineVariant;
      contentColor = colorScheme.onSurface;
      mutedColor = colorScheme.onSurfaceVariant;
      statusLabel = 'Completed';
      statusIcon = Icons.check_circle_outline;
      statusBackgroundColor = colorScheme.surfaceContainerHighest;
      statusForegroundColor = colorScheme.onSurfaceVariant;
    } else if (timer.isRunning) {
      progressColor = colorScheme.primary;
      cardColor = colorScheme.surfaceContainerLow;
      borderColor = colorScheme.outlineVariant;
      contentColor = colorScheme.onSurface;
      mutedColor = colorScheme.onSurfaceVariant;
      statusLabel = 'Running';
      statusIcon = Icons.play_circle_outline;
      statusBackgroundColor = colorScheme.primaryContainer;
      statusForegroundColor = colorScheme.onPrimaryContainer;
    } else {
      progressColor = colorScheme.tertiary;
      cardColor = colorScheme.surfaceContainerLow;
      borderColor = colorScheme.outlineVariant;
      contentColor = colorScheme.onSurface;
      mutedColor = colorScheme.onSurfaceVariant;
      statusLabel = 'Paused';
      statusIcon = Icons.pause_circle_outline;
      statusBackgroundColor = colorScheme.tertiaryContainer;
      statusForegroundColor = colorScheme.onTertiaryContainer;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: isRecoveredOverdue ? 0 : 1,
      clipBehavior: Clip.antiAlias,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: isRecoveredOverdue ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    timer.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: contentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _StatusBadge(
                      label: statusLabel,
                      icon: statusIcon,
                      backgroundColor: statusBackgroundColor,
                      foregroundColor: statusForegroundColor,
                    ),
                    const SizedBox(width: 6),
                    _ActionMenuButton(
                      tooltip: 'More Actions',
                      foregroundColor: contentColor,
                      backgroundColor: isRecoveredOverdue ? colorScheme.error.withOpacity(0.08) : colorScheme.surface,
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
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: isRecoveredOverdue ? colorScheme.error.withOpacity(0.12) : colorScheme.surfaceContainerHighest,
                color: progressColor,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _MetricCard(
                    label: 'Target',
                    value: '${timer.characteristics.volume.toStringAsFixed(1)} ml',
                    valueColor: contentColor,
                    labelColor: mutedColor,
                    backgroundColor: isRecoveredOverdue ? colorScheme.error.withOpacity(0.08) : colorScheme.surface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Infused',
                    value: '${timer.infusedVolume.toStringAsFixed(1)} ml',
                    valueColor: contentColor,
                    labelColor: mutedColor,
                    backgroundColor: isRecoveredOverdue ? colorScheme.error.withOpacity(0.08) : colorScheme.surface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Remaining',
                    value: remainingTime,
                    valueColor: contentColor,
                    labelColor: mutedColor,
                    backgroundColor: isRecoveredOverdue ? colorScheme.error.withOpacity(0.08) : colorScheme.surface,
                    emphasize: true,
                  ),
                ),
              ],
            ),
            if (isRecoveredOverdue) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Completed while the app was unavailable. Review this infusion.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: contentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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

String _formatRemainingTime(Duration remainingDuration) {
  final int totalSeconds = remainingDuration.inSeconds;
  final int hours = totalSeconds ~/ 3600;
  final int minutes = (totalSeconds % 3600) ~/ 60;
  final int seconds = totalSeconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.labelColor,
    required this.backgroundColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color labelColor;
  final Color backgroundColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                softWrap: false,
                style: (emphasize ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(
                  color: valueColor,
                  fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
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
        padding: const EdgeInsets.all(8),
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
