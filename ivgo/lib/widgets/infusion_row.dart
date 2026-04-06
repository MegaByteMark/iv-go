import 'package:flutter/material.dart';
import 'package:ivgo/utils/infusion_stopwatch_timer.dart';

class InfusionRow extends StatelessWidget {
  final InfusionStopwatchTimer timer;
  final void Function(InfusionStopwatchTimer theTimer)? onRemove;
  final void Function(InfusionStopwatchTimer theTimer)? onEdit;
  final void Function(InfusionStopwatchTimer theTimer)? onChanged;

  const InfusionRow(this.timer, {super.key, this.onRemove, this.onEdit, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isRecoveredOverdue = timer.isRecoveredOverdue;
    final int remainingMinutes = timer.remainingSeconds.inSeconds ~/ 60;
    final int remainingSeconds = timer.remainingSeconds.inSeconds % 60;
    final Color progressColor;

    if (isRecoveredOverdue) {
      progressColor = theme.colorScheme.error;
    } else if (timer.isEnded) {
      progressColor = theme.colorScheme.outline;
    } else if (timer.isRunning) {
      progressColor = Colors.green;
    } else {
      progressColor = theme.colorScheme.tertiary;
    }

    return ListTile(
      isThreeLine: isRecoveredOverdue,
      tileColor: isRecoveredOverdue ? theme.colorScheme.errorContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecoveredOverdue ? BorderSide(color: theme.colorScheme.error, width: 1.5) : BorderSide.none,
      ),
      title: Text(
        timer.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isRecoveredOverdue ? theme.colorScheme.onErrorContainer : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(
                color: isRecoveredOverdue ? theme.colorScheme.onErrorContainer : null,
              ),
              children: [
                TextSpan(text: 'Volume: ${timer.characteristics.volume.toStringAsFixed(1)} ml'),
                const TextSpan(text: ' '),
                TextSpan(
                  text: 'Infused: ${timer.infusedVolume.toStringAsFixed(1)} ml, Remaining: ${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (isRecoveredOverdue) ...[
            const SizedBox(height: 4),
            Text(
              'Completed while the app was unavailable. Review this infusion.',
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      leading: Container(
        width: 10,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        child: FractionallySizedBox(
          heightFactor: (timer.infusedVolume / timer.characteristics.volume).clamp(0.0, 1.0),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 10,
            color: progressColor,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isRecoveredOverdue)
            IconButton(
              icon: Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.error,
              ),
              tooltip: 'Acknowledge Recovered Timer',
              onPressed: () {
                timer.acknowledgeRecoveredOverdue();

                if (onChanged != null) {
                  onChanged!(timer);
                }
              },
            ),
          IconButton(
            icon: Icon(Icons.edit_outlined),
            tooltip: 'Edit Infusion',
            onPressed: () {
              if (onEdit != null) {
                onEdit!(timer);
              }
            },
          ),
          if (!timer.isEnded)
            IconButton(
              icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                if (timer.isRunning) {
                  timer.stop();
                } else {
                  timer.start();
                }

                if (onChanged != null) {
                  onChanged!(timer);
                }
              },
              tooltip: timer.isRunning ? 'Pause' : 'Resume',
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              timer.reset();

              if (onChanged != null) {
                onChanged!(timer);
              }
            },
            tooltip: 'Reset',
          ),
          IconButton(
            icon: Icon(Icons.delete_outlined, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Confirm Removal'),
                    content: Text('Are you sure you want to remove this infusion?'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Remove'),
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
            },
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
