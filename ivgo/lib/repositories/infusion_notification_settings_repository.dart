import 'dart:convert';

import 'package:ivgo/domain/infusion_notification_milestone.dart';
import 'package:ivgo/domain/infusion_notification_trigger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InfusionNotificationSettingsRepository {
  InfusionNotificationSettingsRepository({
    Future<SharedPreferences> Function()? sharedPreferencesFactory,
  }) : _sharedPreferencesFactory = sharedPreferencesFactory ?? SharedPreferences.getInstance;

  static final List<InfusionNotificationMilestone> _defaultMilestones = <InfusionNotificationMilestone>[
    InfusionNotificationMilestone(
      key: 'one_minute_remaining',
      title: 'One Minute Remaining',
      offset: const Duration(minutes: 1),
      trigger: InfusionNotificationTrigger.beforeEnd,
    ),
    InfusionNotificationMilestone(
      key: 'ten_minutes_remaining',
      title: '10 Minutes Remaining',
      offset: const Duration(minutes: 10),
      trigger: InfusionNotificationTrigger.beforeEnd,
    ),
    InfusionNotificationMilestone(
      key: 'ended_plus_ten_minutes',
      title: 'Infusion ended 10 minutes ago',
      offset: Duration(minutes: 10),
      trigger: InfusionNotificationTrigger.afterEnd,
    ),
  ];

  static const String _storageKey = 'infusionNotificationMilestones';

  final Future<SharedPreferences> Function() _sharedPreferencesFactory;

  Future<List<InfusionNotificationMilestone>> loadMilestones() async {
    final SharedPreferences prefs = await _sharedPreferencesFactory();
    final List<String>? milestonesJson = prefs.getStringList(_storageKey);

    if (milestonesJson == null) {
      return List<InfusionNotificationMilestone>.of(_defaultMilestones);
    }

    try {
      return milestonesJson
          .map(
            (String json) {
              final decoded = jsonDecode(json);

              if(decoded is! Map<String, dynamic>) {
                throw FormatException('Invalid JSON format for InfusionNotificationMilestone');
              }

              return InfusionNotificationMilestone.fromJson(decoded);
            }
          )
          .toList();
    } catch (_) {
      // If parsing fails, return default milestones
      return List<InfusionNotificationMilestone>.of(_defaultMilestones);
    }
  }

  Future<void> saveMilestones(List<InfusionNotificationMilestone> milestones) async {
    final SharedPreferences prefs = await _sharedPreferencesFactory();
    final List<String> milestonesJson = milestones.map((InfusionNotificationMilestone milestone) => jsonEncode(milestone.toJson())).toList();

    await prefs.setStringList(_storageKey, milestonesJson);
  }
}
