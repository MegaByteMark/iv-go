import 'package:ivgo/domain/infusion_notification_trigger.dart';

class InfusionNotificationMilestone {
  final String key;
  final String title;
  final String body;
  final Duration offset;
  final InfusionNotificationTrigger trigger;

  InfusionNotificationMilestone({
    required this.key,
    required this.offset,
    required this.title,
    required this.body,
    required this.trigger,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'body': body,
      'offset': offset.inSeconds,
      'trigger': trigger.name,
    };
  }

  factory InfusionNotificationMilestone.fromJson(Map<String, dynamic> json) {
    return InfusionNotificationMilestone(
      key: json['key'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      offset: Duration(seconds: json['offset'] as int),
      trigger: InfusionNotificationTrigger.values.byName(
        json['trigger'] as String,
      ),
    );
  }
}
