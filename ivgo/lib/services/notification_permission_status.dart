enum NotificationPermissionStatus {
  notDetermined,
  granted,
  denied,
  unavailable,
}

extension NotificationPermissionStatusMessages on NotificationPermissionStatus {
  String? get warningMessage {
    return switch (this) {
      NotificationPermissionStatus.denied =>
        'Notifications are turned off. Background alerts will not function. Re-enable notifications in system settings and monitor timers in-app until alerts are restored.',
      NotificationPermissionStatus.unavailable => 'Notifications are unavailable on this device or platform. Background alerts will not function. Monitor timers in-app.',
      NotificationPermissionStatus.granted || NotificationPermissionStatus.notDetermined => null,
    };
  }

  String get requestFeedbackMessage {
    return switch (this) {
      NotificationPermissionStatus.granted => 'Notification permissions granted. Background alerts are enabled.',
      NotificationPermissionStatus.denied => 'Notification permissions denied. Re-enable notifications in system settings and monitor timers in-app until alerts are restored.',
      NotificationPermissionStatus.unavailable => 'Notification permissions are unavailable on this device or platform. Monitor timers in-app because background alerts will not function.',
      NotificationPermissionStatus.notDetermined => 'Notification permissions not granted yet. Monitor timers in-app until background alerts are enabled.',
    };
  }
}
