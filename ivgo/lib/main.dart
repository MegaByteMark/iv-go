import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ivgo/pages/disclaimer_page.dart';
import 'package:ivgo/pages/infusion_list_page.dart';
import 'package:ivgo/repositories/disclaimer_acceptance_repository.dart';
import 'package:ivgo/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(IVGoApp(notificationService: notificationService));
}

class IVGoApp extends StatelessWidget {
  IVGoApp({
    super.key,
    required this.notificationService,
    DisclaimerAcceptanceRepository? disclaimerAcceptanceRepository,
  }) : disclaimerAcceptanceRepository = disclaimerAcceptanceRepository ?? DisclaimerAcceptanceRepository();

  final NotificationService notificationService;
  final DisclaimerAcceptanceRepository disclaimerAcceptanceRepository;

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
      home: _StartupGate(
        notificationService: notificationService,
        disclaimerAcceptanceRepository: disclaimerAcceptanceRepository,
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({
    required this.notificationService,
    required this.disclaimerAcceptanceRepository,
  });

  final NotificationService notificationService;
  final DisclaimerAcceptanceRepository disclaimerAcceptanceRepository;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  static const Duration _disclaimerLoadTimeout = Duration(seconds: 3);

  bool? _hasAcceptedDisclaimer;

  @override
  void initState() {
    super.initState();
    _loadDisclaimerAcceptance();
  }

  @override
  Widget build(BuildContext context) {
    final bool? hasAcceptedDisclaimer = _hasAcceptedDisclaimer;

    if (hasAcceptedDisclaimer == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!hasAcceptedDisclaimer) {
      return DisclaimerPage(
        onAccepted: _handleDisclaimerAccepted,
      );
    }

    return InfusionListPage(
      title: 'Active Infusions',
      notificationService: widget.notificationService,
    );
  }

  Future<void> _loadDisclaimerAcceptance() async {
    bool hasAcceptedDisclaimer = false;

    try {
      hasAcceptedDisclaimer = await widget.disclaimerAcceptanceRepository.hasAcceptedDisclaimer().timeout(_disclaimerLoadTimeout, onTimeout: () => false);
    } catch (_) {
      hasAcceptedDisclaimer = false;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _hasAcceptedDisclaimer = hasAcceptedDisclaimer;
    });
  }

  Future<void> _handleDisclaimerAccepted() async {
    await widget.disclaimerAcceptanceRepository.recordAcceptedDisclaimer();

    if (!mounted) {
      return;
    }

    setState(() {
      _hasAcceptedDisclaimer = true;
    });
  }
}
