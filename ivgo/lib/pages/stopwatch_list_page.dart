import 'package:flutter/material.dart';
import 'package:ivgo/utils/infusion_stopwatch_timer.dart';

class StopwatchListPage extends StatefulWidget {
  const StopwatchListPage({super.key, required this.title});

  final String title;

  @override
  State<StopwatchListPage> createState() => _StopwatchListPageState();
}

class _StopwatchListPageState extends State<StopwatchListPage> {
  List<InfusionStopwatchTimer> timers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView(
        children: <Widget>[
          // Add your list of widgets here
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTimer,
        tooltip: 'Add New Infusion',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNewTimer() {
    //TODO
  }
}
