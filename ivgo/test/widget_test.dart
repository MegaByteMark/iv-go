import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/domain/infusion_characteristics.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/main.dart';
import 'package:ivgo/repositories/disclaimer_acceptance_repository.dart';
import 'package:ivgo/services/notification_permission_status.dart';
import 'package:ivgo/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_disclaimer_acceptance_repository.dart';
import 'fakes/fake_notification_service.dart';

const String deniedPermissionWarning =
    'Notifications are turned off. Background alerts will not function. Re-enable notifications in system settings and monitor timers in-app until alerts are restored.';
const String unavailablePermissionWarning = 'Notifications are unavailable on this device or platform. Background alerts will not function. Monitor timers in-app.';
const String disclaimerTitle = 'Before you begin';
const String disclaimerAcknowledgement =
    'I understand that IVGo is a job aid and not an automated infusion controller, and that I remain responsible for clinical decisions, equipment checks, and active monitoring.';

class ThrowingDisclaimerAcceptanceRepository extends DisclaimerAcceptanceRepository {
  @override
  Future<bool> hasAcceptedDisclaimer() async {
    throw Exception('Failed to load disclaimer acceptance');
  }
}

class NeverCompletingDisclaimerAcceptanceRepository extends DisclaimerAcceptanceRepository {
  @override
  Future<bool> hasAcceptedDisclaimer() {
    return Completer<bool>().future;
  }
}

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    NotificationService? notificationService,
    DisclaimerAcceptanceRepository? disclaimerAcceptanceRepository,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      IVGoApp(
        notificationService: notificationService ?? FakeNotificationService(),
        disclaimerAcceptanceRepository: disclaimerAcceptanceRepository ?? FakeDisclaimerAcceptanceRepository(initialAccepted: true),
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> acceptDisclaimer(WidgetTester tester) async {
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Accept and continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the disclaimer on first launch and records acceptance', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final DisclaimerAcceptanceRepository disclaimerAcceptanceRepository = DisclaimerAcceptanceRepository();

    await pumpApp(
      tester,
      disclaimerAcceptanceRepository: disclaimerAcceptanceRepository,
    );

    expect(find.text(disclaimerTitle), findsOneWidget);
    expect(
      find.text(
        'IVGo is a job aid for tracking infusion progress when automated systems are unavailable or unsuitable. It does not control infusion delivery.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('You remain responsible for clinical decisions'),
      findsOneWidget,
    );
    expect(find.text(disclaimerAcknowledgement), findsOneWidget);
    expect(find.text('No active infusions'), findsNothing);

    final FilledButton buttonBeforeConfirmation = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Accept and continue'),
    );
    expect(buttonBeforeConfirmation.onPressed, isNull);

    await acceptDisclaimer(tester);

    expect(find.text(disclaimerTitle), findsNothing);
    expect(find.text('No active infusions'), findsOneWidget);

    expect(
      await disclaimerAcceptanceRepository.hasAcceptedDisclaimer(),
      isTrue,
    );
  });

  testWidgets('skips the disclaimer once it has been accepted', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      disclaimerAcceptanceRepository: FakeDisclaimerAcceptanceRepository(initialAccepted: true),
    );

    expect(find.text(disclaimerTitle), findsNothing);
    expect(find.text('No active infusions'), findsOneWidget);
  });

  testWidgets('shows the disclaimer if loading acceptance fails', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      disclaimerAcceptanceRepository: ThrowingDisclaimerAcceptanceRepository(),
    );

    expect(find.text(disclaimerTitle), findsOneWidget);
    expect(find.text('No active infusions'), findsNothing);
  });

  testWidgets('shows the disclaimer if loading acceptance stalls', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      disclaimerAcceptanceRepository: NeverCompletingDisclaimerAcceptanceRepository(),
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text(disclaimerTitle), findsOneWidget);
    expect(find.text('No active infusions'), findsNothing);
  });

  Future<void> addTimer(
    WidgetTester tester, {
    String title = 'Saline',
    String volume = '6',
    String dropFactor = '20',
    String flowRate = '60',
  }) async {
    await tester.tap(find.byTooltip('Add New Infusion'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), title);
    await tester.enterText(find.byType(TextFormField).at(1), volume);
    await tester.enterText(find.byType(TextFormField).at(2), dropFactor);
    await tester.enterText(find.byType(TextFormField).at(3), flowRate);

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty infusion state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await pumpApp(tester);

    expect(find.text('No active infusions'), findsOneWidget);
    expect(find.byTooltip('Add New Infusion'), findsOneWidget);
  });

  testWidgets('rejects an empty timer form', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
    });

    await pumpApp(tester);

    await tester.tap(find.byTooltip('Add New Infusion'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('Enter volume'), findsOneWidget);
    expect(find.text('Enter drop factor'), findsOneWidget);
    expect(find.text('Enter flow rate'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('rejects invalid numeric values when adding a timer', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
    });

    await pumpApp(tester);

    await tester.tap(find.byTooltip('Add New Infusion'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Saline');
    await tester.enterText(find.byType(TextFormField).at(1), 'abc');
    await tester.enterText(find.byType(TextFormField).at(2), '-5');
    await tester.enterText(find.byType(TextFormField).at(3), '0');

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('volume must be a number'), findsOneWidget);
    expect(find.text('drop factor must be greater than 0'), findsOneWidget);
    expect(find.text('flow rate must be greater than 0'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('restores persisted timers into the list', (WidgetTester tester) async {
    final timer = InfusionTimer(
      1,
      'Saline',
      InfusionCharacteristics(volume: 6, dropFactor: 20, flowRate: 60),
    );

    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
      'infusionTimers': <String>[jsonEncode(timer.toJson())],
    });

    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('Saline'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('highlights timers recovered as overdue after downtime', (WidgetTester tester) async {
    final Map<String, dynamic> recoveredTimerJson = <String, dynamic>{
      'id': 1,
      'title': 'Saline',
      'characteristics': <String, dynamic>{
        'volume': 6.0,
        'dropFactor': 20.0,
        'flowRate': 60.0,
      },
      'initialCharacteristics': <String, dynamic>{
        'volume': 6.0,
        'dropFactor': 20.0,
        'flowRate': 60.0,
      },
      'status': 'running',
      'lastStartedAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      'completedAt': null,
      'phases': <Map<String, dynamic>>[],
    };

    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
      'infusionTimers': <String>[jsonEncode(recoveredTimerJson)],
    });

    await pumpApp(tester);

    expect(
      find.text('Completed while the app was unavailable. Review this infusion.'),
      findsOneWidget,
    );

    final ListTile recoveredTile = tester.widget<ListTile>(find.byType(ListTile));
    expect(recoveredTile.tileColor, isNotNull);
  });

  testWidgets('acknowledging a recovered timer clears the warning state', (WidgetTester tester) async {
    final Map<String, dynamic> recoveredTimerJson = <String, dynamic>{
      'id': 1,
      'title': 'Saline',
      'characteristics': <String, dynamic>{
        'volume': 6.0,
        'dropFactor': 20.0,
        'flowRate': 60.0,
      },
      'initialCharacteristics': <String, dynamic>{
        'volume': 6.0,
        'dropFactor': 20.0,
        'flowRate': 60.0,
      },
      'status': 'running',
      'lastStartedAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      'completedAt': null,
      'phases': <Map<String, dynamic>>[],
    };

    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
      'infusionTimers': <String>[jsonEncode(recoveredTimerJson)],
    });

    await pumpApp(tester);

    expect(find.byTooltip('Acknowledge Recovered Timer'), findsOneWidget);

    await tester.tap(find.byTooltip('Acknowledge Recovered Timer'));
    await tester.pumpAndSettle();

    expect(
      find.text('Completed while the app was unavailable. Review this infusion.'),
      findsNothing,
    );
    expect(find.byTooltip('Acknowledge Recovered Timer'), findsNothing);

    final ListTile acknowledgedTile = tester.widget<ListTile>(find.byType(ListTile));
    expect(acknowledgedTile.tileColor, isNull);
  });

  testWidgets('invalid edits do not overwrite an existing timer', (WidgetTester tester) async {
    final timer = InfusionTimer(
      1,
      'Saline',
      InfusionCharacteristics(volume: 6, dropFactor: 20, flowRate: 60),
    );

    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
      'infusionTimers': <String>[jsonEncode(timer.toJson())],
    });

    await pumpApp(tester);

    await tester.tap(find.byTooltip('Edit Infusion'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), '0');

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('volume must be greater than 0'), findsOneWidget);
    expect(find.text('Edit Infusion :: Saline'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Saline'), findsOneWidget);
    expect(find.textContaining('Volume: 6.0 ml'), findsOneWidget);
  });

  testWidgets('requests notification permissions from the app bar action', (WidgetTester tester) async {
    await pumpApp(
      tester,
      notificationService: FakeNotificationService(permissionResult: true),
    );

    expect(find.byTooltip('Enable Notifications'), findsOneWidget);

    await tester.tap(find.byTooltip('Enable Notifications'));
    await tester.pump(); // start the snackbar frame

    expect(
      find.text('Notification permissions granted. Background alerts are enabled.'),
      findsOneWidget,
    );
  });

  testWidgets('does not show the permission warning banner before a denial', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
    });

    await pumpApp(tester);

    expect(
      find.text(deniedPermissionWarning),
      findsNothing,
    );
  });

  testWidgets('restoring persisted timers resyncs milestone notifications', (WidgetTester tester) async {
    final timer = InfusionTimer(
      1,
      'Saline',
      InfusionCharacteristics(volume: 6, dropFactor: 20, flowRate: 60),
    );
    final fakeNotificationService = FakeNotificationService();

    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
      'infusionTimers': <String>[jsonEncode(timer.toJson())],
    });

    await pumpApp(tester, notificationService: fakeNotificationService);

    expect(fakeNotificationService.scheduledMilestoneCalls, 1);
    expect(fakeNotificationService.scheduledTimerIds, <int>[1]);
  });

  testWidgets('adding a timer schedules milestone notifications', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
    });
    final fakeNotificationService = FakeNotificationService();

    await pumpApp(tester, notificationService: fakeNotificationService);
    await addTimer(tester);

    expect(fakeNotificationService.scheduledMilestoneCalls, 1);
    expect(fakeNotificationService.scheduledTimerIds, <int>[1]);
  });

  testWidgets('pausing a timer resyncs milestone notifications', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
    });
    final fakeNotificationService = FakeNotificationService();

    await pumpApp(tester, notificationService: fakeNotificationService);
    await addTimer(tester);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();

    expect(fakeNotificationService.scheduledMilestoneCalls, 2);
    expect(fakeNotificationService.scheduledTimerIds, <int>[1, 1]);
  });

  testWidgets('removing a timer cancels milestone notifications', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
    });
    final fakeNotificationService = FakeNotificationService();

    await pumpApp(tester, notificationService: fakeNotificationService);
    await addTimer(tester);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(fakeNotificationService.cancelledMilestoneCalls, 1);
    expect(fakeNotificationService.cancelledTimerIds, <int>[1]);
  });

  testWidgets('shows a denied snackbar when notification permissions are not granted', (WidgetTester tester) async {
    await pumpApp(
      tester,
      notificationService: FakeNotificationService(permissionResult: false),
    );

    await tester.tap(find.byTooltip('Enable Notifications'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Notification permissions denied. Re-enable notifications in system settings and monitor timers in-app until alerts are restored.',
      ),
      findsOneWidget,
    );
    expect(find.text(deniedPermissionWarning), findsOneWidget);
  });

  testWidgets('shows the permission warning banner for an existing denied state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
    });

    await pumpApp(
      tester,
      notificationService: FakeNotificationService(
        initialPermissionStatus: NotificationPermissionStatus.denied,
      ),
    );

    expect(find.text(deniedPermissionWarning), findsOneWidget);
  });

  testWidgets('shows the permission warning banner for an existing unavailable state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
    });

    await pumpApp(
      tester,
      notificationService: FakeNotificationService(
        initialPermissionStatus: NotificationPermissionStatus.unavailable,
      ),
    );

    expect(find.text(unavailablePermissionWarning), findsOneWidget);
  });

  testWidgets('denied warning does not block creating a timer', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
    });

    await pumpApp(
      tester,
      notificationService: FakeNotificationService(
        initialPermissionStatus: NotificationPermissionStatus.denied,
      ),
    );

    expect(find.text(deniedPermissionWarning), findsOneWidget);

    await addTimer(tester);

    expect(find.text('Saline'), findsOneWidget);
    expect(find.textContaining('Volume: 6.0 ml'), findsOneWidget);
    expect(find.text(deniedPermissionWarning), findsOneWidget);
  });

  testWidgets('denied warning does not block pause resume and remove actions', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
    });

    await pumpApp(
      tester,
      notificationService: FakeNotificationService(
        initialPermissionStatus: NotificationPermissionStatus.denied,
      ),
    );
    await addTimer(tester);

    expect(find.text(deniedPermissionWarning), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Resume'), findsOneWidget);

    await tester.tap(find.byTooltip('Resume'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Saline'), findsNothing);
    expect(find.text('No active infusions'), findsOneWidget);
    expect(find.text(deniedPermissionWarning), findsOneWidget);
  });

  testWidgets('unavailable warning does not block core timer use', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hasAcceptedDisclaimer': true,
    });

    await pumpApp(
      tester,
      notificationService: FakeNotificationService(
        initialPermissionStatus: NotificationPermissionStatus.unavailable,
      ),
    );

    expect(find.text(unavailablePermissionWarning), findsOneWidget);

    await addTimer(tester, title: 'Dextrose');

    expect(find.text('Dextrose'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Resume'), findsOneWidget);

    await tester.tap(find.byTooltip('Resume'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Dextrose'), findsNothing);
    expect(find.text('No active infusions'), findsOneWidget);
    expect(find.text(unavailablePermissionWarning), findsOneWidget);
  });
}
