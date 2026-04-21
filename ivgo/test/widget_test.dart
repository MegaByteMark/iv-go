import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/domain/infusion_characteristics.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/main.dart';
import 'package:ivgo/services/notification_permission_status.dart';
import 'package:ivgo/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_notification_service.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, {NotificationService? notificationService}) async {
    await tester.pumpWidget(
      IVGoApp(notificationService: notificationService ?? FakeNotificationService()),
    );

    await tester.pumpAndSettle();
  }

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
    SharedPreferences.setMockInitialValues(<String, Object>{});

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
    SharedPreferences.setMockInitialValues(<String, Object>{});

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

    expect(find.text('Notification permissions granted'), findsOneWidget);
  });

  testWidgets('does not show the permission warning banner before a denial', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await pumpApp(tester);

    expect(
      find.text(
        'Notification permissions denied. Background alerts will not function. Please monitor timers in-app.',
      ),
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
      'infusionTimers': <String>[jsonEncode(timer.toJson())],
    });

    await pumpApp(tester, notificationService: fakeNotificationService);

    expect(fakeNotificationService.scheduledMilestoneCalls, 1);
    expect(fakeNotificationService.scheduledTimerIds, <int>[1]);
  });

  testWidgets('adding a timer schedules milestone notifications', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final fakeNotificationService = FakeNotificationService();

    await pumpApp(tester, notificationService: fakeNotificationService);
    await addTimer(tester);

    expect(fakeNotificationService.scheduledMilestoneCalls, 1);
    expect(fakeNotificationService.scheduledTimerIds, <int>[1]);
  });

  testWidgets('pausing a timer resyncs milestone notifications', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final fakeNotificationService = FakeNotificationService();

    await pumpApp(tester, notificationService: fakeNotificationService);
    await addTimer(tester);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();

    expect(fakeNotificationService.scheduledMilestoneCalls, 2);
    expect(fakeNotificationService.scheduledTimerIds, <int>[1, 1]);
  });

  testWidgets('removing a timer cancels milestone notifications', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
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

    expect(find.text('Notification permissions not granted'), findsOneWidget);
    expect(
      find.text(
        'Notification permissions denied. Background alerts will not function. Please monitor timers in-app.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the permission warning banner for an existing denied state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await pumpApp(
      tester,
      notificationService: FakeNotificationService(
        initialPermissionStatus: NotificationPermissionStatus.denied,
      ),
    );

    expect(
      find.text(
        'Notification permissions denied. Background alerts will not function. Please monitor timers in-app.',
      ),
      findsOneWidget,
    );
  });
}
