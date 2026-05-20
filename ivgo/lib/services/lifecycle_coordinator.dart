import 'dart:async';

import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/repositories/infusion_timer_repository.dart';
import 'package:ivgo/services/notification_service.dart';

class LifecycleCoordinator {
  LifecycleCoordinator({
    required InfusionTimerRepository timerRepository,
    required NotificationService notificationService,
  })  : _timerRepository = timerRepository,
        _notificationService = notificationService;

  final InfusionTimerRepository _timerRepository;
  final NotificationService _notificationService;

  Future<List<InfusionTimer>> onStartup() async {
    final List<InfusionTimer> timers = await _timerRepository.loadTimers();

    for (final timer in timers) {
      timer.onRestore();
    }

    await _rescheduleNotifications(timers);

    return timers;
  }

  void onForeground(List<InfusionTimer> timers) {
    for (final timer in timers) {
      timer.reconcile();
    }

    unawaited(_rescheduleNotifications(timers));
  }

  Future<void> onBackground(List<InfusionTimer> timers) async {
    await _timerRepository.saveTimers(timers);
  }

  Future<void> saveTimers(List<InfusionTimer> timers) async {
    await _timerRepository.saveTimers(timers);
  }

  Future<void> rescheduleNotifications(List<InfusionTimer> timers) async {
    await _rescheduleNotifications(timers);
  }

  Future<void> _rescheduleNotifications(List<InfusionTimer> timers) async {
    for (final timer in timers) {
      await _notificationService.scheduleMilestonesForTimer(
        timer,
        suppressAlreadyDeliveredBeforeEndMilestones: true,
      );
    }
  }
}
