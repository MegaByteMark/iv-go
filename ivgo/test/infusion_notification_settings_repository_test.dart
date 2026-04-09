import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/domain/infusion_notification_milestone.dart';
import 'package:ivgo/domain/infusion_notification_trigger.dart';
import 'package:ivgo/repositories/infusion_notification_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('InfusionNotificationSettingsRepository', () {
    late InfusionNotificationSettingsRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = InfusionNotificationSettingsRepository();
    });

    test('returns default milestones when nothing is stored', () async {
      final List<InfusionNotificationMilestone> milestones = await repository.loadMilestones();

      expect(milestones, hasLength(3));
      expect(milestones[0].key, 'one_minute_remaining');
      expect(milestones[0].offset, const Duration(minutes: 1));
      expect(milestones[0].trigger, InfusionNotificationTrigger.beforeEnd);
      expect(milestones[1].key, 'ten_minutes_remaining');
      expect(milestones[1].offset, const Duration(minutes: 10));
      expect(milestones[2].key, 'ended_plus_ten_minutes');
      expect(milestones[2].offset, const Duration(minutes: 10));
      expect(milestones[2].trigger, InfusionNotificationTrigger.afterEnd);
    });

    test('saves and restores milestones through shared preferences', () async {
      final List<InfusionNotificationMilestone> milestones = <InfusionNotificationMilestone>[
        InfusionNotificationMilestone(
          key: 'custom_before_end',
          title: 'Custom Before End',
          body: 'Your infusion will complete in 3 minutes.',
          offset: const Duration(minutes: 3),
          trigger: InfusionNotificationTrigger.beforeEnd,
        ),
        InfusionNotificationMilestone(
          key: 'custom_after_end',
          title: 'Custom After End',
          body: 'Your infusion completed 12 minutes ago.',
          offset: const Duration(minutes: 12),
          trigger: InfusionNotificationTrigger.afterEnd,
        ),
      ];

      await repository.saveMilestones(milestones);
      final List<InfusionNotificationMilestone> restoredMilestones = await repository.loadMilestones();

      expect(restoredMilestones, hasLength(2));
      expect(restoredMilestones[0].key, 'custom_before_end');
      expect(restoredMilestones[0].title, 'Custom Before End');
      expect(restoredMilestones[0].offset, const Duration(minutes: 3));
      expect(restoredMilestones[0].trigger, InfusionNotificationTrigger.beforeEnd);
      expect(restoredMilestones[1].key, 'custom_after_end');
      expect(restoredMilestones[1].title, 'Custom After End');
      expect(restoredMilestones[1].offset, const Duration(minutes: 12));
      expect(restoredMilestones[1].trigger, InfusionNotificationTrigger.afterEnd);
    });

    test('falls back to defaults when stored milestone JSON is invalid', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'infusionNotificationMilestones': <String>[
          'not valid json',
          jsonEncode(<String, dynamic>{
            'key': 'broken',
            'title': 'Broken',
            'offset': 60,
            'trigger': 'beforeEnd',
          }),
        ],
      });

      repository = InfusionNotificationSettingsRepository();

      final List<InfusionNotificationMilestone> milestones = await repository.loadMilestones();

      expect(milestones, hasLength(3));
      expect(milestones[0].key, 'one_minute_remaining');
      expect(milestones[1].key, 'ten_minutes_remaining');
      expect(milestones[2].key, 'ended_plus_ten_minutes');
    });
  });
}