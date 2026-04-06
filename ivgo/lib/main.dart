import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ivgo/pages/stopwatch_list_page.dart';
import 'package:ivgo/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(IVGoApp(notificationService: notificationService));
}

class IVGoApp extends StatelessWidget {
  const IVGoApp({super.key, required this.notificationService});

  final NotificationService notificationService;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IVGo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: Colors.lightBlue,
        ),
      ),
      home: StopwatchListPage(title: 'Active Infusions', notificationService: notificationService),
    );
  }
}
