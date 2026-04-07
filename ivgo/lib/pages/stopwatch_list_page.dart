import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ivgo/domain/infusion_characteristics.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/repositories/infusion_timer_repository.dart';
import 'package:gap/gap.dart';
import 'package:ivgo/services/notification_service.dart';
import 'package:ivgo/widgets/infusion_row.dart';

class StopwatchListPage extends StatefulWidget {
  StopwatchListPage({
    super.key,
    required this.title,
    required this.notificationService,
    InfusionTimerRepository? timerRepository,
  }) : timerRepository = timerRepository ?? InfusionTimerRepository();

  final String title;
  final InfusionTimerRepository timerRepository;
  final NotificationService notificationService;

  @override
  State<StopwatchListPage> createState() => _StopwatchListPageState();
}

class _StopwatchListPageState extends State<StopwatchListPage> with WidgetsBindingObserver {
  List<InfusionTimer> infusionTimers = [];
  Timer? refreshTimer;

  Future<void> saveState() async {
    await widget.timerRepository.saveTimers(infusionTimers);
  }

  Future<void> loadState() async {
    final List<InfusionTimer> restoredTimers = await widget.timerRepository.loadTimers();

    for (final timer in restoredTimers) {
      timer.onRestore();
    }

    if (!mounted) {
      infusionTimers = restoredTimers;
      return;
    }

    setState(() {
      infusionTimers = restoredTimers;
      _manageRefreshTimer();
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    loadState();
    _manageRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(saveState());

    refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        for (final timer in infusionTimers) {
          timer.reconcile();
        }

        if (mounted) {
          setState(() {
            _manageRefreshTimer();
          });
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(saveState());
    }
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
                onChanged: (_) {
                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    _manageRefreshTimer();
                  });

                  unawaited(saveState());
                },
                onRemove: (theTimer) {
                  setState(() {
                    theTimer.stop();
                    infusionTimers.remove(theTimer);
                    _manageRefreshTimer();
                  });

                  unawaited(saveState());
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _requestNotificationPermissions,
            tooltip: 'Enable Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.alarm_outlined),
            tooltip: 'Enable Exact Alarms',
            onPressed: _requestExactAlarmPermission,
          ),
          IconButton(
            icon: const Icon(Icons.notification_add_outlined),
            tooltip: 'Send Test Notification',
            onPressed: _sendTestNotification,
          ),
          IconButton(
            icon: const Icon(Icons.schedule_outlined),
            tooltip: 'Send Test Scheduled Notification',
            onPressed: _scheduleTestNotification,
          ),
        ],
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

  Future<void> _sendTestNotification() async {
    await widget.notificationService.showTestNotification();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent'),
      ),
    );
  }

  Future<void> _requestNotificationPermissions() async {
    final bool granted = await widget.notificationService.requestPermissions();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted ? 'Notification permissions granted' : 'Notification permissions not granted',
        ),
      ),
    );
  }

  void _manageRefreshTimer() {
    final bool hasRunningTimers = infusionTimers.any((timer) => timer.isRunning);

    if (hasRunningTimers) {
      refreshTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
        for (final infusionTimer in infusionTimers) {
          infusionTimer.reconcile();
        }

        if (infusionTimers.isEmpty || !infusionTimers.any((infusionTimer) => infusionTimer.isRunning)) {
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

  Future<void> _addOrEditTimer(InfusionTimer? theTimer) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final bool isNewTimer = theTimer == null;
        final GlobalKey<FormState> formKey = GlobalKey<FormState>();
        final TextEditingController titleController = TextEditingController();
        final TextEditingController volumeController = TextEditingController();
        final TextEditingController dropFactorController = TextEditingController();
        final TextEditingController flowRateController = TextEditingController();
        AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

        if (!isNewTimer) {
          titleController.text = theTimer?.title ?? '';
          volumeController.text = theTimer?.characteristics.volume.toString() ?? '';
          dropFactorController.text = theTimer?.characteristics.dropFactor.toString() ?? '';
          flowRateController.text = theTimer?.characteristics.flowRate.toString() ?? '';
        }

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: (isNewTimer) ? Text('New Infusion') : Text('Edit Infusion :: ${theTimer!.title}'),
              content: Form(
                key: formKey,
                autovalidateMode: autovalidateMode,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      validator: _validateTitle,
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: volumeController,
                      decoration: const InputDecoration(labelText: 'Volume (ml)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: (value) => _validatePositiveNumber(value, 'volume'),
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: dropFactorController,
                      decoration: const InputDecoration(labelText: 'Drop Factor (gtts/ml)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: (value) => _validatePositiveNumber(value, 'drop factor'),
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: flowRateController,
                      decoration: const InputDecoration(labelText: 'Flow Rate (gtts/min)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      validator: (value) => _validatePositiveNumber(value, 'flow rate'),
                    ),
                  ],
                ),
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
                    FocusScope.of(context).unfocus();

                    setDialogState(() {
                      autovalidateMode = AutovalidateMode.onUserInteraction;
                    });

                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final String title = titleController.text.trim();
                    final double volume = double.parse(volumeController.text.trim());
                    final double dropFactor = double.parse(dropFactorController.text.trim());
                    final double flowRate = double.parse(flowRateController.text.trim());

                    if (isNewTimer) {
                      theTimer = InfusionTimer(
                        _nextTimerId(),
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

                    unawaited(saveState());
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a title';
    }

    return null;
  }

  String? _validatePositiveNumber(String? value, String fieldName) {
    final String trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Enter $fieldName';
    }

    final double? parsedValue = double.tryParse(trimmedValue);

    if (parsedValue == null) {
      return '$fieldName must be a number';
    }

    if (parsedValue <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  int _nextTimerId() {
    return infusionTimers.fold<int>(0, (int maxId, InfusionTimer timer) {
          return timer.id > maxId ? timer.id : maxId;
        }) +
        1;
  }

  Future<void> _scheduleTestNotification() async {
    await widget.notificationService.scheduleTestNotification();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test scheduled notification set for 10 seconds from now'),
      ),
    );
  }

  Future<void> _requestExactAlarmPermission() async {
    final bool granted = await widget.notificationService.requestExactAlarmPermission();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted ? 'Exact alarm permission granted' : 'Exact alarm permission not granted',
        ),
      ),
    );
  }
}
