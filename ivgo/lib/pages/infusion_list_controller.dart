import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ivgo/domain/infusion_characteristics.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/services/lifecycle_coordinator.dart';
import 'package:ivgo/services/notification_service.dart';
import 'package:signals_flutter/signals_flutter.dart';

class InfusionListController {
  InfusionListController({
    required LifecycleCoordinator lifecycleCoordinator,
    required NotificationService notificationService,
  })  : _lifecycleCoordinator = lifecycleCoordinator,
        _notificationService = notificationService;

  final LifecycleCoordinator _lifecycleCoordinator;
  final NotificationService _notificationService;
  final Signal<List<InfusionTimer>> _infusionTimers = signal(
    <InfusionTimer>[],
    debugLabel: 'infusionListTimers',
  );

  Timer? _refreshTimer;
  bool _disposed = false;
  List<InfusionTimer> _cachedTimers = <InfusionTimer>[];

  ReadonlySignal<List<InfusionTimer>> get infusionTimers => _infusionTimers;

  List<InfusionTimer> get currentTimers => _infusionTimers.value;

  Future<void> initialize() async {
    _manageRefreshTimer();

    final List<InfusionTimer> restoredTimers = await _lifecycleCoordinator.onStartup();

    if (_disposed) {
      return;
    }

    _replaceInfusionTimers(restoredTimers);
    _manageRefreshTimer();
  }

  Future<void> saveState() async {
    if (_disposed) {
      return;
    }

    await _lifecycleCoordinator.saveTimers(currentTimers);
  }

  void handleLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _lifecycleCoordinator.onForeground(currentTimers);

        if (_disposed) {
          return;
        }

        _manageRefreshTimer();
        _refreshInfusionTimers();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_lifecycleCoordinator.onBackground(currentTimers));
    }
  }

  Future<InfusionTimer> addTimer({
    required String title,
    required InfusionCharacteristics characteristics,
  }) async {
    final InfusionTimer timer = InfusionTimer(
      _nextTimerId(),
      title,
      characteristics,
    );

    timer.start();
    _replaceInfusionTimers(List<InfusionTimer>.of(currentTimers)..add(timer));
    _manageRefreshTimer();
    await _syncTimerNotifications(timer);
    await saveState();

    return timer;
  }

  Future<InfusionTimer> updateTimer({
    required InfusionTimer timer,
    required String title,
    required InfusionCharacteristics characteristics,
  }) async {
    timer.title = title;
    timer.changeCharacteristics(characteristics);
    _refreshInfusionTimers();
    _manageRefreshTimer();
    await _syncTimerNotifications(timer);
    await saveState();

    return timer;
  }

  Future<void> handleTimerChanged(InfusionTimer timer) async {
    if (_disposed) {
      return;
    }

    _manageRefreshTimer();
    _refreshInfusionTimers();
    await _syncTimerNotifications(timer);
  }

  Future<void> removeTimer(InfusionTimer timer) async {
    if (_disposed) {
      return;
    }

    timer.stop();
    _replaceInfusionTimers(List<InfusionTimer>.of(currentTimers)..remove(timer));
    _manageRefreshTimer();
    await _cancelTimerNotifications(timer);
    await saveState();
  }

  Future<void> clearCompletedTimers() async {
    if (_disposed) {
      return;
    }

    final List<InfusionTimer> completedTimers = currentTimers.where((timer) => timer.isEnded).toList(growable: false);

    if (completedTimers.isEmpty) {
      return;
    }

    final List<InfusionTimer> remainingTimers = currentTimers.where((timer) => !timer.isEnded).toList();

    _replaceInfusionTimers(remainingTimers);
    _manageRefreshTimer();

    for (final InfusionTimer timer in completedTimers) {
      await _notificationService.cancelMilestonesForTimer(timer);
    }

    await saveState();
  }

  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    unawaited(_lifecycleCoordinator.saveTimers(_cachedTimers));
    _infusionTimers.dispose();
  }

  void _replaceInfusionTimers(List<InfusionTimer> timers) {
    if (_disposed) {
      return;
    }

    _cachedTimers = timers;
    _infusionTimers.value = timers;
  }

  void _refreshInfusionTimers() {
    _replaceInfusionTimers(List<InfusionTimer>.of(currentTimers));
  }

  void _manageRefreshTimer() {
    if (_disposed) {
      return;
    }

    final bool hasRunningTimers = currentTimers.any((timer) => timer.isRunning);

    if (hasRunningTimers) {
      _refreshTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_disposed) {
          timer.cancel();
          _refreshTimer = null;
          return;
        }

        for (final infusionTimer in currentTimers) {
          infusionTimer.reconcile();
        }

        _refreshInfusionTimers();

        if (currentTimers.isEmpty || !currentTimers.any((infusionTimer) => infusionTimer.isRunning)) {
          timer.cancel();
          _refreshTimer = null;
        }
      });

      return;
    }

    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  int _nextTimerId() {
    return currentTimers.fold<int>(0, (int maxId, InfusionTimer timer) {
          return timer.id > maxId ? timer.id : maxId;
        }) +
        1;
  }

  Future<void> _syncTimerNotifications(InfusionTimer timer) async {
    if (_disposed) {
      return;
    }

    await _notificationService.scheduleMilestonesForTimer(timer);
    await saveState();
  }

  Future<void> _cancelTimerNotifications(InfusionTimer timer) async {
    if (_disposed) {
      return;
    }

    await _notificationService.cancelMilestonesForTimer(timer);
    await saveState();
  }
}
