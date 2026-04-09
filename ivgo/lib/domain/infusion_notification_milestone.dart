import 'package:ivgo/domain/infusion_notification_trigger.dart';

class InfusionNotificationMilestone {
  final String key;
  final String title;
  final Duration offset;
  final InfusionNotificationTrigger trigger;

  InfusionNotificationMilestone({
    required this.key,
    required this.offset,
    required this.title,
    required this.trigger,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'offset': offset.inSeconds,
      'trigger': trigger.name,
    };
  }

  factory InfusionNotificationMilestone.fromJson(Map<String, dynamic> json) {
    return InfusionNotificationMilestone(
      key: json['key'] as String,
      title: json['title'] as String,
      offset: Duration(seconds: json['offset'] as int),
      trigger: InfusionNotificationTrigger.values.byName(
        json['trigger'] as String,
      ),
    );
  }
}
