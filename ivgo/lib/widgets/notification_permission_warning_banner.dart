import 'package:flutter/material.dart';
import 'package:ivgo/services/notification_permission_status.dart';
import 'package:ivgo/services/notification_service.dart';
import 'package:signals_flutter/signals_flutter.dart';

class NotificationPermissionWarningBanner extends StatelessWidget {
  const NotificationPermissionWarningBanner({
    super.key,
    required this.notificationService,
  });

  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final NotificationPermissionStatus status = notificationService.permissionStatus.value;
      final String? message = status.warningMessage;

      if (message == null) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.8),
        padding: const EdgeInsets.all(8.0),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
          textAlign: TextAlign.center,
        ),
      );
    });
  }
}
