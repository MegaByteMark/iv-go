import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/main.dart';
import 'package:ivgo/pages/onboarding_wizard.dart';
import 'package:ivgo/repositories/disclaimer_acceptance_repository.dart';
import 'package:ivgo/repositories/first_launch_repository.dart';
import 'package:ivgo/repositories/infusion_timer_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_disclaimer_acceptance_repository.dart';
import 'fakes/fake_first_launch_repository.dart';
import 'fakes/fake_notification_service.dart';

class FakeInfusionTimerRepository extends InfusionTimerRepository {
  FakeInfusionTimerRepository();

  @override
  Future<List<InfusionTimer>> loadTimers() async => <InfusionTimer>[];

  @override
  Future<void> saveTimers(List<InfusionTimer> timers) async {}
}

class NeverCompletingFirstLaunchRepository extends FirstLaunchRepository {
  @override
  Future<bool> hasSeenOnboarding() {
    final Completer<bool> completer = Completer<bool>();
    return completer.future;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpAppWithOnboarding({
    required WidgetTester tester,
    required DisclaimerAcceptanceRepository disclaimerAcceptanceRepository,
    required FirstLaunchRepository firstLaunchRepository,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      IVGoApp(
        notificationService: FakeNotificationService(),
        disclaimerAcceptanceRepository: disclaimerAcceptanceRepository,
        firstLaunchRepository: firstLaunchRepository,
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('Onboarding Wizard', () {
    testWidgets('renders all 7 pages', (WidgetTester tester) async {
      await pumpAppWithOnboarding(
        tester: tester,
        disclaimerAcceptanceRepository: FakeDisclaimerAcceptanceRepository(initialAccepted: true),
        firstLaunchRepository: FakeFirstLaunchRepository(initialSeen: false),
      );

      expect(find.byType(OnboardingWizard), findsOneWidget);
      expect(find.text('Welcome to IV Go'), findsOneWidget);
      expect(find.byIcon(Icons.vaccines), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Name Your Infusion'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Set Your Target'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Configure Flow Rate'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Stay Notified'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text("That's it!"), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text("You're All Set!"), findsOneWidget);
    });

    testWidgets('skip dismisses to main list', (WidgetTester tester) async {
      await pumpAppWithOnboarding(
        tester: tester,
        disclaimerAcceptanceRepository: FakeDisclaimerAcceptanceRepository(initialAccepted: true),
        firstLaunchRepository: FakeFirstLaunchRepository(initialSeen: false),
      );

      expect(find.byType(OnboardingWizard), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingWizard), findsNothing);
      expect(find.text('No active infusions'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('next and back navigation works', (WidgetTester tester) async {
      await pumpAppWithOnboarding(
        tester: tester,
        disclaimerAcceptanceRepository: FakeDisclaimerAcceptanceRepository(initialAccepted: true),
        firstLaunchRepository: FakeFirstLaunchRepository(initialSeen: false),
      );

      expect(find.text('Welcome to IV Go'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Name Your Infusion'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to IV Go'), findsOneWidget);
    });

    testWidgets('can navigate through all wizard steps with valid input', (WidgetTester tester) async {
      await pumpAppWithOnboarding(
        tester: tester,
        disclaimerAcceptanceRepository: FakeDisclaimerAcceptanceRepository(initialAccepted: true),
        firstLaunchRepository: FakeFirstLaunchRepository(initialSeen: false),
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Name Your Infusion'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Set Your Target'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Target Volume (ml)'), '500');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Configure Flow Rate'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Drop Factor (gtts/ml)'), '20');
      await tester.enterText(find.widgetWithText(TextField, 'Flow Rate (gtts/min)'), '30');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Stay Notified'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text("That's it!"), findsOneWidget);
    });

    testWidgets('back navigation is disabled on first page', (WidgetTester tester) async {
      await pumpAppWithOnboarding(
        tester: tester,
        disclaimerAcceptanceRepository: FakeDisclaimerAcceptanceRepository(initialAccepted: true),
        firstLaunchRepository: FakeFirstLaunchRepository(initialSeen: false),
      );

      final backButton = find.widgetWithText(OutlinedButton, 'Back');
      expect(backButton, findsNothing);
    });

    testWidgets('live preview updates on create step', (WidgetTester tester) async {
      await pumpAppWithOnboarding(
        tester: tester,
        disclaimerAcceptanceRepository: FakeDisclaimerAcceptanceRepository(initialAccepted: true),
        firstLaunchRepository: FakeFirstLaunchRepository(initialSeen: false),
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Infusion Name'), 'Test Infusion');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Target Volume (ml)'), '1000');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Drop Factor (gtts/ml)'), '15');
      await tester.enterText(find.widgetWithText(TextField, 'Flow Rate (gtts/min)'), '60');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Stay Notified'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text("That's it!"), findsOneWidget);
      expect(find.text('Test Infusion'), findsOneWidget);
    });

    testWidgets('final page shows create timer button', (WidgetTester tester) async {
      await pumpAppWithOnboarding(
        tester: tester,
        disclaimerAcceptanceRepository: FakeDisclaimerAcceptanceRepository(initialAccepted: true),
        firstLaunchRepository: FakeFirstLaunchRepository(initialSeen: false),
      );

      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text("You're All Set!"), findsOneWidget);
      expect(find.text('Create Infusion Timer'), findsOneWidget);
    });

    testWidgets('creating the timer completes onboarding and shows the main list', (WidgetTester tester) async {
      final FakeFirstLaunchRepository firstLaunchRepository = FakeFirstLaunchRepository(initialSeen: false);

      await pumpAppWithOnboarding(
        tester: tester,
        disclaimerAcceptanceRepository: FakeDisclaimerAcceptanceRepository(initialAccepted: true),
        firstLaunchRepository: firstLaunchRepository,
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Infusion Name'), 'Walkthrough Infusion');

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Target Volume (ml)'), '250');

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Drop Factor (gtts/ml)'), '15');
      await tester.enterText(find.widgetWithText(TextField, 'Flow Rate (gtts/min)'), '45');

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Create Infusion Timer'), findsOneWidget);

      await tester.tap(find.text('Create Infusion Timer'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingWizard), findsNothing);
      expect(find.text('Walkthrough Infusion'), findsOneWidget);
      expect(find.byTooltip('Add New Infusion'), findsOneWidget);
      expect(await firstLaunchRepository.hasSeenOnboarding(), isTrue);
    });
  });
}
