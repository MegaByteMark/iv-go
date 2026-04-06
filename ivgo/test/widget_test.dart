import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/main.dart';
import 'package:ivgo/models/infusion_characteristics.dart';
import 'package:ivgo/utils/infusion_stopwatch_timer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the empty infusion state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const IVGoApp());
    await tester.pumpAndSettle();

    expect(find.text('No active infusions'), findsOneWidget);
    expect(find.byTooltip('Add New Infusion'), findsOneWidget);
  });

  testWidgets('restores persisted timers into the list', (WidgetTester tester) async {
    final timer = InfusionStopwatchTimer(
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
}
