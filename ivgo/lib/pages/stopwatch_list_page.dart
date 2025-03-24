import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ivgo/models/infusion_characteristics.dart';
import 'package:ivgo/utils/infusion_stopwatch_timer.dart';
import 'package:gap/gap.dart';
import 'package:ivgo/widgets/infusion_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StopwatchListPage extends StatefulWidget {
  const StopwatchListPage({super.key, required this.title});

  final String title;

  @override
  State<StopwatchListPage> createState() => _StopwatchListPageState();
}

class _StopwatchListPageState extends State<StopwatchListPage> {
  List<InfusionStopwatchTimer> infusionTimers = [];
  Timer? refreshTimer;

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> timersJson = infusionTimers.map((timer) => jsonEncode(timer.toJson())).toList();
    await prefs.setStringList('infusionTimers', timersJson);
  }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? timersJson = prefs.getStringList('infusionTimers');

    if (timersJson != null) {
      infusionTimers = timersJson.map((json) => InfusionStopwatchTimer.fromJson(jsonDecode(json))).toList();

      for (final timer in infusionTimers) {
        timer.onRestore();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    loadState();
    _manageRefreshTimer();
  }

  @override
  void dispose() {
    saveState();

    refreshTimer?.cancel();
    super.dispose();
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
                    theTimer.stop();
                    infusionTimers.remove(theTimer);
                    _manageRefreshTimer();
                  });
                },
                onEdit: (theTimer) async {
                  await _addOrEditTimer(theTimer);
                  _manageRefreshTimer();
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
        onPressed: () async {
          await _addOrEditTimer(null);
          _manageRefreshTimer();
        },
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

  Future<void> _addOrEditTimer(InfusionStopwatchTimer? theTimer) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isNewTimer = theTimer == null;
        final TextEditingController titleController = TextEditingController();
        final TextEditingController volumeController = TextEditingController();
        final TextEditingController dropFactorController = TextEditingController();
        final TextEditingController flowRateController = TextEditingController();

        if (!isNewTimer) {
          titleController.text = theTimer?.title ?? '';
          volumeController.text = theTimer?.characteristics.volume.toString() ?? '';
          dropFactorController.text = theTimer?.characteristics.dropFactor.toString() ?? '';
          flowRateController.text = theTimer?.characteristics.flowRate.toString() ?? '';
        }

        return AlertDialog(
          title: (isNewTimer) ? Text('New Infusion') : Text('Edit Infusion :: ${theTimer!.title}'),
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
              child: (isNewTimer) ? Text('Add') : Text('Save'),
              onPressed: () {
                final String title = titleController.text;
                final double volume = double.tryParse(volumeController.text) ?? 0.0;
                final double dropFactor = double.tryParse(dropFactorController.text) ?? 0.0;
                final double flowRate = double.tryParse(flowRateController.text) ?? 0.0;

                if (isNewTimer) {
                  theTimer = InfusionStopwatchTimer(
                    infusionTimers.length + 1,
                    title,
                    InfusionCharacteristics(
                      volume: volume,
                      dropFactor: dropFactor,
                      flowRate: flowRate,
                    ),
                  );

                  infusionTimers.add(theTimer!);
                  theTimer!.start();
                } else {
                  theTimer!.title = title;
                  theTimer!.changeCharacteristics(InfusionCharacteristics(
                    volume: volume,
                    dropFactor: dropFactor,
                    flowRate: flowRate,
                  ));
                }

                Navigator.of(context).pop();

                setState(() {
                  _manageRefreshTimer();
                });
              },
            ),
          ],
        );
      },
    );
  }
}
