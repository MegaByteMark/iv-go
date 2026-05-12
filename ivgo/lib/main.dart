import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ivgo/pages/disclaimer_page.dart';
import 'package:ivgo/pages/infusion_list_page.dart';
import 'package:ivgo/pages/infusion_list_controller.dart';
import 'package:ivgo/pages/onboarding_wizard.dart';
import 'package:ivgo/repositories/disclaimer_acceptance_repository.dart';
import 'package:ivgo/repositories/first_launch_repository.dart';
import 'package:ivgo/repositories/infusion_timer_repository.dart';
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
    FirstLaunchRepository? firstLaunchRepository,
  })  : disclaimerAcceptanceRepository = disclaimerAcceptanceRepository ?? DisclaimerAcceptanceRepository(),
        firstLaunchRepository = firstLaunchRepository ?? FirstLaunchRepository();

  final NotificationService notificationService;
  final DisclaimerAcceptanceRepository disclaimerAcceptanceRepository;
  final FirstLaunchRepository firstLaunchRepository;

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
        firstLaunchRepository: firstLaunchRepository,
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({
    required this.notificationService,
    required this.disclaimerAcceptanceRepository,
    required this.firstLaunchRepository,
  });

  final NotificationService notificationService;
  final DisclaimerAcceptanceRepository disclaimerAcceptanceRepository;
  final FirstLaunchRepository firstLaunchRepository;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  static const Duration _loadTimeout = Duration(seconds: 3);

  bool? _hasAcceptedDisclaimer;
  bool? _hasSeenOnboarding;

  late final InfusionListController _infusionListController;

  @override
  void initState() {
    super.initState();
    _infusionListController = InfusionListController(
      timerRepository: InfusionTimerRepository(),
      notificationService: widget.notificationService,
    );
    _loadStartupState();
  }

  @override
  void dispose() {
    _infusionListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool? hasAcceptedDisclaimer = _hasAcceptedDisclaimer;
    final bool? hasSeenOnboarding = _hasSeenOnboarding;

    if (hasAcceptedDisclaimer == null || hasSeenOnboarding == null) {
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

    if (!hasSeenOnboarding) {
      return OnboardingWizard(
        controller: _infusionListController,
        onComplete: _handleOnboardingComplete,
        onSkip: _handleOnboardingComplete,
      );
    }

    return InfusionListPage(
      title: 'Active Infusions',
      notificationService: widget.notificationService,
      infusionListController: _infusionListController,
    );
  }

  Future<void> _loadStartupState() async {
    bool hasAcceptedDisclaimer = false;
    bool hasSeenOnboarding = false;

    try {
      final results = await Future.wait([
        widget.disclaimerAcceptanceRepository.hasAcceptedDisclaimer().timeout(_loadTimeout, onTimeout: () => false),
        widget.firstLaunchRepository.hasSeenOnboarding().timeout(_loadTimeout, onTimeout: () => false),
      ]);
      hasAcceptedDisclaimer = results[0];
      hasSeenOnboarding = results[1];
    } catch (_) {
      hasAcceptedDisclaimer = false;
      hasSeenOnboarding = false;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _hasAcceptedDisclaimer = hasAcceptedDisclaimer;
      _hasSeenOnboarding = hasSeenOnboarding;
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

  Future<void> _handleOnboardingComplete() async {
    await widget.firstLaunchRepository.setHasSeenOnboarding(true);

    if (!mounted) {
      return;
    }

    setState(() {
      _hasSeenOnboarding = true;
    });
  }
}