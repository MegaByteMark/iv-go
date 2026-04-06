import 'package:ivgo/services/notification_service.dart';

class FakeNotificationService extends NotificationService {
  FakeNotificationService({this.permissionResult = true});

  final bool permissionResult;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async => permissionResult;
}