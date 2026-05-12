import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/main.dart';
import 'package:ivgo/pages/settings_page.dart';
import 'package:ivgo/repositories/first_launch_repository.dart';

import 'fakes/fake_disclaimer_acceptance_repository.dart';
import 'fakes/fake_first_launch_repository.dart';
import 'fakes/fake_notification_service.dart';

void main() {
  Future<void> pumpAppWithSettings({
    required WidgetTester tester,
    required FirstLaunchRepository firstLaunchRepository,
  }) async {
    await tester.pumpWidget(
      IVGoApp(
        notificationService: FakeNotificationService(),
        disclaimerAcceptanceRepository: FakeDisclaimerAcceptanceRepository(initialAccepted: true),
        firstLaunchRepository: firstLaunchRepository,
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

  testWidgets('settings page shows dark mode option (disabled)', (WidgetTester tester) async {
    final firstLaunchRepository = FakeFirstLaunchRepository(initialSeen: true);

    await pumpAppWithSettings(
      tester: tester,
      firstLaunchRepository: firstLaunchRepository,
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Use dark theme (coming soon)'), findsOneWidget);

    final SwitchListTile switchTile = tester.widget(find.byType(SwitchListTile));
    expect(switchTile.onChanged, isNull);
  });
}