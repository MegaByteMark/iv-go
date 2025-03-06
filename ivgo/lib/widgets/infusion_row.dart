import 'package:flutter/material.dart';
import 'package:ivgo/utils/infusion_stopwatch_timer.dart';

class InfusionRow extends StatelessWidget {
  final InfusionStopwatchTimer timer;
  final void Function(InfusionStopwatchTimer theTimer)? onRemove;

  const InfusionRow(this.timer, {super.key, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        timer.title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Volume: ${timer.volume.toStringAsFixed(1)} ml, Flow Rate: ${timer.flowRate.toStringAsFixed(1)} ml/hr, '),
            TextSpan(
              text: 'Infused: ${timer.infusedVolume.toStringAsFixed(1)} ml',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      leading: Container(
        width: 10,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        child: FractionallySizedBox(
          heightFactor: (timer.infusedVolume / timer.volume).clamp(0.0, 1.0),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 10,
            color: Colors.green,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (timer.infusedVolume < timer.volume)
            IconButton(
              icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                if (timer.isRunning) {
                  timer.stop();
                } else {
                  timer.start();
                }
              },
              tooltip: timer.isRunning ? 'Pause' : 'Resume',
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: timer.reset,
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
