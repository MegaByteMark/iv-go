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
      title: 'Less Than One Minute Remaining',
      body: 'Infusion {timer.title} has less than 1 minute remaining.',
      offset: const Duration(minutes: 1),
      trigger: InfusionNotificationTrigger.beforeEnd,
    ),
    InfusionNotificationMilestone(
      key: 'ten_minutes_remaining',
      title: 'Less Than 10 Minutes Remaining',
      body: 'Infusion {timer.title} has less than 10 minutes remaining.',
      offset: const Duration(minutes: 10),
      trigger: InfusionNotificationTrigger.beforeEnd,
    ),InfusionNotificationMilestone(
      key: 'ended_plus_ten_seconds',
      title: 'Infusion complete',
      body: 'Infusion {timer.title} has completed.',
      offset: const Duration(seconds: 10),
      trigger: InfusionNotificationTrigger.afterEnd,
    ),
    InfusionNotificationMilestone(
      key: 'ended_plus_ten_minutes',
      title: 'Infusion completed 10 minutes ago',
      body: 'Infusion {timer.title} has completed 10 minutes ago.',
      offset: const Duration(minutes: 10),
      trigger: InfusionNotificationTrigger.afterEnd,
    ),
  ];

  static const String _storageKey = 'infusionNotificationMilestones';

  final Future<SharedPreferences> Function() _sharedPreferencesFactory;

  Future<List<InfusionNotificationMilestone>> loadMilestones() async {
    try {
      final SharedPreferences prefs = await _sharedPreferencesFactory();
      final List<String>? milestonesJson = prefs.getStringList(_storageKey);

      if (milestonesJson == null) {
        return List<InfusionNotificationMilestone>.of(_defaultMilestones);
      }

      return milestonesJson.map((String json) {
        final decoded = jsonDecode(json);

        if (decoded is! Map<String, dynamic>) {
          throw FormatException('Invalid JSON format for InfusionNotificationMilestone');
        }

        return InfusionNotificationMilestone.fromJson(decoded);
      }).toList();
    } catch (_) {
      // If storage access or parsing fails, return default milestones.
      return List<InfusionNotificationMilestone>.of(_defaultMilestones);
    }
  }

  Future<void> saveMilestones(List<InfusionNotificationMilestone> milestones) async {
    final SharedPreferences prefs = await _sharedPreferencesFactory();
    final List<String> milestonesJson = milestones.map((InfusionNotificationMilestone milestone) => jsonEncode(milestone.toJson())).toList();

    await prefs.setStringList(_storageKey, milestonesJson);
  }
}
