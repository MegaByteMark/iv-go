import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/main.dart';
import 'package:ivgo/pages/settings_page.dart';
import 'package:ivgo/repositories/disclaimer_acceptance_repository.dart';
import 'package:ivgo/repositories/first_launch_repository.dart';
import 'package:ivgo/repositories/theme_repository.dart';

import 'fakes/fake_disclaimer_acceptance_repository.dart';
import 'fakes/fake_first_launch_repository.dart';
import 'fakes/fake_notification_service.dart';
import 'fakes/fake_theme_repository.dart';

void main() {
  Future<void> pumpAppWithSettings({
    required WidgetTester tester,
    required FirstLaunchRepository firstLaunchRepository,
    DisclaimerAcceptanceRepository? disclaimerAcceptanceRepository,
    ThemeRepository? themeRepository,
  }) async {
    await tester.pumpWidget(
      IVGoApp(
        notificationService: FakeNotificationService(),
        disclaimerAcceptanceRepository: disclaimerAcceptanceRepository ?? FakeDisclaimerAcceptanceRepository(initialAccepted: true),
        firstLaunchRepository: firstLaunchRepository,
        themeRepository: themeRepository ?? FakeThemeRepository(),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('settings page can be opened from main list', (WidgetTester tester) async {
    await pumpAppWithSettings(
      tester: tester,
      firstLaunchRepository: FakeFirstLaunchRepository(initialSeen: true),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('settings page shows replay walkthrough option', (WidgetTester tester) async {
    final firstLaunchRepository = FakeFirstLaunchRepository(initialSeen: true);

    await pumpAppWithSettings(
      tester: tester,
      firstLaunchRepository: firstLaunchRepository,
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Replay Walkthrough'), findsOneWidget);
    expect(find.text('Show the onboarding wizard again'), findsOneWidget);
  });

  testWidgets('replay walkthrough resets onboarding state', (WidgetTester tester) async {
    final firstLaunchRepository = FakeFirstLaunchRepository(initialSeen: true);

    await pumpAppWithSettings(
      tester: tester,
      firstLaunchRepository: firstLaunchRepository,
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Replay Walkthrough'));
    await tester.pumpAndSettle();

    expect(await firstLaunchRepository.hasSeenOnboarding(), isFalse);
    expect(find.text('Walkthrough will show on next app launch'), findsOneWidget);
  });

  testWidgets('settings page shows reset disclaimer option', (WidgetTester tester) async {
    await pumpAppWithSettings(
      tester: tester,
      firstLaunchRepository: FakeFirstLaunchRepository(initialSeen: true),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Disclaimer'), findsOneWidget);
    expect(find.text('Show the safety disclaimer again'), findsOneWidget);
  });

  testWidgets('reset disclaimer resets disclaimer acceptance state', (WidgetTester tester) async {
    final disclaimerRepository = FakeDisclaimerAcceptanceRepository(initialAccepted: true);

    await pumpAppWithSettings(
      tester: tester,
      firstLaunchRepository: FakeFirstLaunchRepository(initialSeen: true),
      disclaimerAcceptanceRepository: disclaimerRepository,
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset Disclaimer'));
    await tester.pumpAndSettle();

    expect(await disclaimerRepository.hasAcceptedDisclaimer(), isFalse);
    expect(find.text('Disclaimer will show on next app launch'), findsOneWidget);
  });

  testWidgets('settings page shows theme mode segmented control', (WidgetTester tester) async {
    final firstLaunchRepository = FakeFirstLaunchRepository(initialSeen: true);
    final themeRepository = FakeThemeRepository(initialThemeMode: ThemeMode.system);

    await pumpAppWithSettings(
      tester: tester,
      firstLaunchRepository: firstLaunchRepository,
      themeRepository: themeRepository,
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    final SegmentedButton<ThemeMode> segmentedButton = tester.widget(find.byType(SegmentedButton<ThemeMode>));
    expect(segmentedButton.selected, <ThemeMode>{ThemeMode.system});

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(await themeRepository.getThemeMode(), ThemeMode.dark);
  });
}