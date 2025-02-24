import 'package:flutter/material.dart';
import 'package:ivgo/utils/infusion_stopwatch_timer.dart';

class InfusionRow extends StatelessWidget {
  final InfusionStopwatchTimer timer;
  final void Function()? onRemove;

  const InfusionRow(this.timer, {super.key, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(timer.title),
      subtitle: Text('Volume: ${timer.volume} ml, Flow Rate: ${timer.flowRate} ml/hr, Infused: ${timer.infusedVolume} ml'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (timer.isRunning) {
                timer.stop();
              } else {
                timer.start();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.stop),
            onPressed: timer.stop,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: timer.reset,
          ),
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              // Raise an event to tell the parent widget that the timer is to be removed
              if (onRemove != null) {
                onRemove!();
              }
            },
          ),
        ],
      ),
    );
  }
}
