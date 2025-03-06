import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ivgo/utils/infusion_stopwatch_timer.dart';
import 'package:gap/gap.dart';
import 'package:ivgo/widgets/infusion_row.dart';

class StopwatchListPage extends StatefulWidget {
  const StopwatchListPage({super.key, required this.title});

  final String title;

  @override
  State<StopwatchListPage> createState() => _StopwatchListPageState();
}

class _StopwatchListPageState extends State<StopwatchListPage> {
  List<InfusionStopwatchTimer> infusionTimers = [];
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();

    _manageRefreshTimer();
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;

    if (infusionTimers.isEmpty) {
      bodyWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.vaccines, size: 100),
            const SizedBox(height: 16),
            Text(
              'No active infusions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    } else {
      bodyWidget = ListView.builder(
        itemCount: infusionTimers.length,
        itemBuilder: (context, index) {
          final timer = infusionTimers[index];

          return Column(
            children: [
              InfusionRow(
                timer,
                onRemove: (theTimer) {
                  setState(() {
                    infusionTimers.remove(theTimer);

                    _manageRefreshTimer();
                  });
                },
              ),
              const Divider(),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: bodyWidget,
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTimer,
        tooltip: 'Add New Infusion',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _manageRefreshTimer() {
    if (infusionTimers.isNotEmpty) {
      refreshTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
        if (infusionTimers.isEmpty) {
          timer.cancel();
          refreshTimer = null;
        } else {
          setState(() {});
        }
      });
    } else {
      refreshTimer?.cancel();
      refreshTimer = null;
    }
  }

  void _addNewTimer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController volumeController = TextEditingController();
        final TextEditingController dropFactorController = TextEditingController();
        final TextEditingController flowRateController = TextEditingController();

        return AlertDialog(
          title: const Text('New Infusion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              Gap(8),
              TextField(
                controller: volumeController,
                decoration: const InputDecoration(labelText: 'Volume (ml)'),
                keyboardType: TextInputType.number,
              ),
              Gap(8),
              TextField(
                controller: dropFactorController,
                decoration: const InputDecoration(labelText: 'Drop Factor (gtts/ml)'),
                keyboardType: TextInputType.number,
              ),
              Gap(8),
              TextField(
                controller: flowRateController,
                decoration: const InputDecoration(labelText: 'Flow Rate (gtts/min)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final String title = titleController.text;
                final double volume = double.tryParse(volumeController.text) ?? 0.0;
                final double dropFactor = double.tryParse(dropFactorController.text) ?? 0.0;
                final double flowRate = double.tryParse(flowRateController.text) ?? 0.0;

                final newTimer = InfusionStopwatchTimer(
                  infusionTimers.length + 1,
                  title,
                  volume,
                  dropFactor,
                  flowRate,
                );

                setState(() {
                  infusionTimers.add(newTimer);
                  newTimer.start();
                  _manageRefreshTimer();
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
