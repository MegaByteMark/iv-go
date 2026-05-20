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
import 'package:ivgo/repositories/theme_repository.dart';
import 'package:ivgo/services/lifecycle_coordinator.dart';
import 'package:ivgo/services/notification_service.dart';
import 'package:ivgo/widgets/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(IVGoApp(notificationService: notificationService));
}

class IVGoApp extends StatefulWidget {
  IVGoApp({
    super.key,
    required this.notificationService,
    DisclaimerAcceptanceRepository? disclaimerAcceptanceRepository,
    FirstLaunchRepository? firstLaunchRepository,
    ThemeRepository? themeRepository,
  })  : disclaimerAcceptanceRepository = disclaimerAcceptanceRepository ?? DisclaimerAcceptanceRepository(),
        firstLaunchRepository = firstLaunchRepository ?? FirstLaunchRepository(),
        themeRepository = themeRepository ?? ThemeRepository();

  final NotificationService notificationService;
  final DisclaimerAcceptanceRepository disclaimerAcceptanceRepository;
  final FirstLaunchRepository firstLaunchRepository;
  final ThemeRepository themeRepository;

  @override
  State<IVGoApp> createState() => _IVGoAppState();
}

class _IVGoAppState extends State<IVGoApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final ThemeMode loaded = await widget.themeRepository.getThemeMode();

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = loaded;
    });
  }

  Future<void> _onThemeChanged(ThemeMode mode) async {
    await widget.themeRepository.setThemeMode(mode);

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = mode;
    });
  }

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
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue, brightness: Brightness.dark),
        useMaterial3: true,
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: Colors.lightBlue,
        ),
      ),
      themeMode: _themeMode,
      home: _StartupGate(
        notificationService: widget.notificationService,
        disclaimerAcceptanceRepository: widget.disclaimerAcceptanceRepository,
        firstLaunchRepository: widget.firstLaunchRepository,
        themeRepository: widget.themeRepository,
        onThemeChanged: _onThemeChanged,
        themeMode: _themeMode,
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({
    required this.notificationService,
    required this.disclaimerAcceptanceRepository,
    required this.firstLaunchRepository,
    required this.themeRepository,
    required this.onThemeChanged,
    required this.themeMode,
  });

  final NotificationService notificationService;
  final DisclaimerAcceptanceRepository disclaimerAcceptanceRepository;
  final FirstLaunchRepository firstLaunchRepository;
  final ThemeRepository themeRepository;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ThemeMode themeMode;

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
      lifecycleCoordinator: LifecycleCoordinator(
        timerRepository: InfusionTimerRepository(),
        notificationService: widget.notificationService,
      ),
      notificationService: widget.notificationService,
    );
    _infusionListController.initialize();
    _loadStartupState();
  }

  @override
  void dispose() {
    super.dispose();
    _infusionListController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool? hasAcceptedDisclaimer = _hasAcceptedDisclaimer;
    final bool? hasSeenOnboarding = _hasSeenOnboarding;

    if (hasAcceptedDisclaimer == null || hasSeenOnboarding == null) {
      return const SplashScreen();
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
        notificationService: widget.notificationService,
      );
    }

    return InfusionListPage(
      title: 'Active Infusions',
      notificationService: widget.notificationService,
      firstLaunchRepository: widget.firstLaunchRepository,
      disclaimerAcceptanceRepository: widget.disclaimerAcceptanceRepository,
      infusionListController: _infusionListController,
      themeRepository: widget.themeRepository,
      onThemeChanged: widget.onThemeChanged,
      themeMode: widget.themeMode,
    );
  }

  Future<void> _loadStartupState() async {
    bool hasAcceptedDisclaimer = false;
    bool hasSeenOnboarding = false;

    try {
      final stopwatch = Stopwatch()..start();
      final results = await Future.wait([
        widget.disclaimerAcceptanceRepository.hasAcceptedDisclaimer().timeout(_loadTimeout, onTimeout: () => false),
        widget.firstLaunchRepository.hasSeenOnboarding().timeout(_loadTimeout, onTimeout: () => false),
      ]);
      hasAcceptedDisclaimer = results[0];
      hasSeenOnboarding = results[1];

      final elapsed = stopwatch.elapsed;
      final minSplashDuration = const Duration(milliseconds: 1800);
      if (elapsed < minSplashDuration) {
        await Future.delayed(minSplashDuration - elapsed);
      }
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