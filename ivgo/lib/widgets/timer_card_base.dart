import 'package:flutter/material.dart';
import 'package:ivgo/domain/infusion_timer.dart';

enum TimerCardMode { running, paused, ended, review }

class TimerCardBase extends StatelessWidget {
  const TimerCardBase({
    super.key,
    this.timer,
    this.previewData,
    this.trailingWidget,
    this.showMenuHint = false,
  }) : assert(timer != null || previewData != null);

  final InfusionTimer? timer;
  final TimerPreviewData? previewData;
  final Widget? trailingWidget;
  final bool showMenuHint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final mode = _computeMode();
    final values = _extractValues();
    final colors = _computeColors(mode, colorScheme);
    final status = _computeStatus(mode, colorScheme);

    return Card(
      margin: EdgeInsets.zero,
      elevation: mode == TimerCardMode.review ? 0 : 1,
      clipBehavior: Clip.antiAlias,
      color: colors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.borderColor, width: mode == TimerCardMode.review ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildHeader(theme, values.title, status.label, status.icon, status.bg, status.fg, colors.contentColor),
            const SizedBox(height: 14),
            _buildProgressBar(mode, values.progress, colors.progressColor, colorScheme),
            const SizedBox(height: 14),
            _buildMetricsRow(values.volume, values.progress, values.remaining, colors.contentColor, colors.mutedColor, mode, colorScheme),
            if (mode == TimerCardMode.review) ...<Widget>[
              const SizedBox(height: 14),
              _buildReviewBanner(theme, colors.contentColor, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  TimerCardMode _computeMode() {
    if (timer != null) {
      if (timer!.isRecoveredOverdue) return TimerCardMode.review;
      if (timer!.isEnded) return TimerCardMode.ended;
      if (timer!.isRunning) return TimerCardMode.running;
      return TimerCardMode.paused;
    }
    return TimerCardMode.running;
  }

  ({String title, double volume, double dropFactor, double flowRate, double progress, Duration remaining}) _extractValues() {
    if (timer != null) {
      final progress = timer!.characteristics.volume <= 0
          ? 0.0
          : (timer!.infusedVolume / timer!.characteristics.volume).clamp(0.0, 1.0);
      return (
        title: timer!.title,
        volume: timer!.characteristics.volume,
        dropFactor: timer!.characteristics.dropFactor,
        flowRate: timer!.characteristics.flowRate,
        progress: progress,
        remaining: timer!.remainingSeconds,
      );
    }
    final hours = previewData!.volume / (previewData!.dropFactor * previewData!.flowRate / 60);
    final remaining = Duration(minutes: (hours * 60).round());
    return (
      title: previewData!.title,
      volume: previewData!.volume,
      dropFactor: previewData!.dropFactor,
      flowRate: previewData!.flowRate,
      progress: 0.0,
      remaining: remaining,
    );
  }

  ({Color cardColor, Color borderColor, Color contentColor, Color mutedColor, Color progressColor}) _computeColors(
    TimerCardMode mode, ColorScheme colorScheme) {
    switch (mode) {
      case TimerCardMode.review:
        return (
          cardColor: colorScheme.errorContainer,
          borderColor: colorScheme.error,
          contentColor: colorScheme.onErrorContainer,
          mutedColor: colorScheme.onErrorContainer,
          progressColor: colorScheme.error,
        );
      case TimerCardMode.ended:
        return (
          cardColor: colorScheme.surfaceContainerLow,
          borderColor: colorScheme.outlineVariant,
          contentColor: colorScheme.onSurface,
          mutedColor: colorScheme.onSurfaceVariant,
          progressColor: colorScheme.outline,
        );
      case TimerCardMode.running:
        return (
          cardColor: colorScheme.surfaceContainerLow,
          borderColor: colorScheme.outlineVariant,
          contentColor: colorScheme.onSurface,
          mutedColor: colorScheme.onSurfaceVariant,
          progressColor: colorScheme.primary,
        );
      case TimerCardMode.paused:
        return (
          cardColor: colorScheme.surfaceContainerLow,
          borderColor: colorScheme.outlineVariant,
          contentColor: colorScheme.onSurface,
          mutedColor: colorScheme.onSurfaceVariant,
          progressColor: colorScheme.tertiary,
        );
    }
  }

  ({String label, IconData icon, Color bg, Color fg}) _computeStatus(
    TimerCardMode mode, ColorScheme colorScheme) {
    switch (mode) {
      case TimerCardMode.review:
        return (
          label: 'Review',
          icon: Icons.warning_amber_rounded,
          bg: colorScheme.error,
          fg: colorScheme.onError,
        );
      case TimerCardMode.ended:
        return (
          label: 'Completed',
          icon: Icons.check_circle_outline,
          bg: colorScheme.surfaceContainerHighest,
          fg: colorScheme.onSurfaceVariant,
        );
      case TimerCardMode.running:
        return (
          label: 'Running',
          icon: Icons.play_circle_outline,
          bg: colorScheme.primaryContainer,
          fg: colorScheme.onPrimaryContainer,
        );
      case TimerCardMode.paused:
        return (
          label: 'Paused',
          icon: Icons.pause_circle_outline,
          bg: colorScheme.tertiaryContainer,
          fg: colorScheme.onTertiaryContainer,
        );
    }
  }

Widget _buildHeader(
    ThemeData theme,
    String title,
    String statusLabel,
    IconData statusIcon,
    Color statusBg,
    Color statusFg,
    Color contentColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            title,
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
            StatusBadge(label: statusLabel, icon: statusIcon, backgroundColor: statusBg, foregroundColor: statusFg),
            if (trailingWidget != null) ...<Widget>[
              const SizedBox(width: 6),
              trailingWidget!,
            ],
            if (showMenuHint) ...<Widget>[
              const SizedBox(width: 6),
              Icon(
                Icons.more_vert,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(TimerCardMode mode, double progress, Color progressColor, ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 10,
        value: progress,
        backgroundColor: mode == TimerCardMode.review
            ? colorScheme.error.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest,
        color: progressColor,
      ),
    );
  }

  Widget _buildMetricsRow(
    double volume,
    double progress,
    Duration remaining,
    Color contentColor,
    Color mutedColor,
    TimerCardMode mode,
    ColorScheme colorScheme,
  ) {
    final infused = volume * progress;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: MetricCard(
            label: 'Target',
            value: '${volume.toStringAsFixed(1)} ml',
            valueColor: contentColor,
            labelColor: mutedColor,
            backgroundColor: mode == TimerCardMode.review ? colorScheme.error.withValues(alpha: 0.08) : colorScheme.surface,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            label: 'Infused',
            value: '${infused.toStringAsFixed(1)} ml',
            valueColor: contentColor,
            labelColor: mutedColor,
            backgroundColor: mode == TimerCardMode.review ? colorScheme.error.withValues(alpha: 0.08) : colorScheme.surface,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            label: 'Remaining',
            value: _formatRemainingTime(remaining),
            valueColor: contentColor,
            labelColor: mutedColor,
            backgroundColor: mode == TimerCardMode.review ? colorScheme.error.withValues(alpha: 0.08) : colorScheme.surface,
            emphasize: true,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewBanner(ThemeData theme, Color contentColor, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
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
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
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
    final theme = Theme.of(context);
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

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
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
    final theme = Theme.of(context);
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

class TimerPreviewData {
  const TimerPreviewData({
    required this.title,
    required this.volume,
    required this.dropFactor,
    required this.flowRate,
  });

  final String title;
  final double volume;
  final double dropFactor;
  final double flowRate;
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