import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ivgo/domain/infusion_characteristics.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/pages/infusion_list_controller.dart';
import 'package:ivgo/repositories/infusion_timer_repository.dart';
import 'package:ivgo/services/notification_permission_status.dart';
import 'package:gap/gap.dart';
import 'package:ivgo/services/notification_service.dart';
import 'package:ivgo/widgets/infusion_row.dart';
import 'package:ivgo/widgets/notification_permission_warning_banner.dart';
import 'package:signals_flutter/signals_flutter.dart';

class InfusionListPage extends StatefulWidget {
  InfusionListPage({
    super.key,
    required this.title,
    required this.notificationService,
    InfusionTimerRepository? timerRepository,
  }) : timerRepository = timerRepository ?? InfusionTimerRepository();

  final String title;
  final InfusionTimerRepository timerRepository;
  final NotificationService notificationService;

  @override
  State<InfusionListPage> createState() => _InfusionListPageState();
}

class _InfusionListPageState extends State<InfusionListPage> with WidgetsBindingObserver {
  late final InfusionListController _controller = InfusionListController(
    timerRepository: widget.timerRepository,
    notificationService: widget.notificationService,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.handleLifecycleStateChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (widget.notificationService.supportsNotificationPermissionRequest)
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: _requestNotificationPermissions,
              tooltip: 'Enable Notifications',
            ),
          if (widget.notificationService.supportsExactAlarmPermissionRequest)
            IconButton(
              icon: const Icon(Icons.alarm_outlined),
              tooltip: 'Enable Exact Alarms',
              onPressed: _requestExactAlarmPermission,
            ),
        ],
      ),
      body: Column(
        children: [
          NotificationPermissionWarningBanner(
            notificationService: widget.notificationService,
          ),
          Expanded(
            child: Watch((context) {
              final List<InfusionTimer> infusionTimers = _controller.infusionTimers.value;

              if (infusionTimers.isEmpty) {
                return Center(
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
              }

              return ListView.builder(
                itemCount: infusionTimers.length,
                itemBuilder: (context, index) {
                  final timer = infusionTimers[index];

                  return Column(
                    children: [
                      InfusionRow(
                        timer,
                        onChanged: (_) => unawaited(_controller.handleTimerChanged(timer)),
                        onRemove: (theTimer) => unawaited(_controller.removeTimer(theTimer)),
                        onEdit: (theTimer) async {
                          final InfusionTimer? savedTimer = await _addOrEditTimer(theTimer);

                          if (savedTimer == null) {
                            return;
                          }
                        },
                      ),
                      const Divider(),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _addOrEditTimer(null);
        },
        tooltip: 'Add New Infusion',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _requestNotificationPermissions() async {
    final bool granted = await widget.notificationService.requestPermissions();

    if (!mounted) {
      return;
    }

    final NotificationPermissionStatus status = granted ? NotificationPermissionStatus.granted : widget.notificationService.permissionStatus.value;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status.requestFeedbackMessage),
      ),
    );
  }

  Future<InfusionTimer?> _addOrEditTimer(InfusionTimer? theTimer) async {
    final _InfusionTimerFormData? formData = await showModalBottomSheet<_InfusionTimerFormData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _InfusionTimerSheet(
          initialTimer: theTimer,
          titleValidator: _validateTitle,
          positiveNumberValidator: _validatePositiveNumber,
        );
      },
    );

    if (formData == null || !mounted) {
      return null;
    }

    if (theTimer == null) {
      return _controller.addTimer(
        title: formData.title,
        characteristics: formData.characteristics,
      );
    }

    return _controller.updateTimer(
      timer: theTimer,
      title: formData.title,
      characteristics: formData.characteristics,
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

class _InfusionTimerSheet extends StatefulWidget {
  const _InfusionTimerSheet({
    required this.initialTimer,
    required this.titleValidator,
    required this.positiveNumberValidator,
  });

  final InfusionTimer? initialTimer;
  final String? Function(String? value) titleValidator;
  final String? Function(String? value, String fieldName) positiveNumberValidator;

  @override
  State<_InfusionTimerSheet> createState() => _InfusionTimerSheetState();
}

class _InfusionTimerSheetState extends State<_InfusionTimerSheet> with SignalsMixin {
  late final _formKey = GlobalKey<FormState>();
  late final _autovalidateMode = createSignal<AutovalidateMode>(
    AutovalidateMode.disabled,
    debugLabel: 'infusionTimerSheetAutovalidateMode',
  );
  late final _titleController = TextEditingController(
    text: widget.initialTimer?.title ?? '',
  );
  late final _volumeController = TextEditingController(
    text: widget.initialTimer?.characteristics.volume.toString() ?? '',
  );
  late final _dropFactorController = TextEditingController(
    text: widget.initialTimer?.characteristics.dropFactor.toString() ?? '',
  );
  late final _flowRateController = TextEditingController(
    text: widget.initialTimer?.characteristics.flowRate.toString() ?? '',
  );

  bool get _isNewTimer => widget.initialTimer == null;

  @override
  void dispose() {
    _titleController.dispose();
    _volumeController.dispose();
    _dropFactorController.dispose();
    _flowRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final MediaQueryData mediaQuery = MediaQuery.of(context);

      return SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidateMode.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      _isNewTimer ? 'New Infusion' : 'Edit Infusion :: ${widget.initialTimer!.title}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Gap(16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      validator: widget.titleValidator,
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: _volumeController,
                      decoration: const InputDecoration(labelText: 'Volume (ml)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: (value) => widget.positiveNumberValidator(value, 'volume'),
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: _dropFactorController,
                      decoration: const InputDecoration(
                        labelText: 'Drop Factor (gtts/ml)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: (value) => widget.positiveNumberValidator(value, 'drop factor'),
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: _flowRateController,
                      decoration: const InputDecoration(
                        labelText: 'Flow Rate (gtts/min)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) => widget.positiveNumberValidator(value, 'flow rate'),
                    ),
                    const Gap(16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        const Gap(8),
                        FilledButton(
                          onPressed: _submit,
                          child: Text(_isNewTimer ? 'Add' : 'Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    _autovalidateMode.value = AutovalidateMode.onUserInteraction;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _InfusionTimerFormData(
        title: _titleController.text.trim(),
        characteristics: InfusionCharacteristics(
          volume: double.parse(_volumeController.text.trim()),
          dropFactor: double.parse(_dropFactorController.text.trim()),
          flowRate: double.parse(_flowRateController.text.trim()),
        ),
      ),
    );
  }
}

class _InfusionTimerFormData {
  const _InfusionTimerFormData({
    required this.title,
    required this.characteristics,
  });

  final String title;
  final InfusionCharacteristics characteristics;
}
