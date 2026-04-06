import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/domain/infusion_characteristics.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the empty infusion state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const IVGoApp());
    await tester.pumpAndSettle();

    expect(find.text('No active infusions'), findsOneWidget);
    expect(find.byTooltip('Add New Infusion'), findsOneWidget);
  });

  testWidgets('rejects an empty timer form', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const IVGoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add New Infusion'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('Enter volume'), findsOneWidget);
    expect(find.text('Enter drop factor'), findsOneWidget);
    expect(find.text('Enter flow rate'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('rejects invalid numeric values when adding a timer', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const IVGoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add New Infusion'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Saline');
    await tester.enterText(find.byType(TextFormField).at(1), 'abc');
    await tester.enterText(find.byType(TextFormField).at(2), '-5');
    await tester.enterText(find.byType(TextFormField).at(3), '0');

    await tester.tap(find.widgetWithText(TextButton, 'Add'));
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

    await tester.pumpWidget(const IVGoApp());
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

    await tester.pumpWidget(const IVGoApp());
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(const IVGoApp());
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(const IVGoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit Infusion'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), '0');

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('volume must be greater than 0'), findsOneWidget);
    expect(find.text('Edit Infusion :: Saline'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Saline'), findsOneWidget);
    expect(find.textContaining('Volume: 6.0 ml'), findsOneWidget);
  });
}
