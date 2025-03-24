import 'dart:async';
import 'package:ivgo/models/infusion_characteristics.dart';

/// A stopwatch timer for tracking the progress of an IV infusion.
class InfusionStopwatchTimer {
  InfusionStopwatchTimer(this.id, this.title, this.characteristics) {
    _initialize();
  }

  late int id;
  late InfusionCharacteristics characteristics;
  late String title;
  double? infusedVolume;
  Duration? durationInSeconds, remainingSeconds;
  DateTime? firstStartTime;
  Timer? _timer;
  bool _isRunning = false;
  bool get isRunning => _isRunning;
  Map<InfusionCharacteristics, Duration> _infusionData = {};

  /// Restores the timer's state from app restart.
  ///
  /// This method is called when the app is reopened. It checks if the timer was running before the app was closed.
  /// If it was running, it works out what elapsed duration was missed and updates the infusionData accordingly.
  ///
  void onRestore() {
    if (_isRunning) {
      final int elapsedSecondsSinceFirstStart = DateTime.now().difference(firstStartTime!).inSeconds;
      _calculateRemainingSeconds();
      final int secondsWhilstAsleep = elapsedSecondsSinceFirstStart - remainingSeconds!.inSeconds;
      _infusionData[characteristics] = Duration(seconds: _infusionData[characteristics]!.inSeconds + secondsWhilstAsleep);
    }

    _ensureTimerIsRunning();
  }

  /// Converts the timer's state to a map of data.
  ///
  /// This method is called when the app is closed. It converts the timer's state to a map of data
  /// that can be stored in a database or file. The data map contains the following:
  /// - id: The timer's unique identifier.
  /// - title: The title of the timer.
  /// - characteristics: The infusion characteristics of the timer.
  /// - infusedVolume: The volume of the IV fluid that has been infused.
  /// - durationInSeconds: The total duration of the infusion in seconds.
  /// - remainingSeconds: The remaining duration of the infusion in seconds.
  /// - firstStartTime: The time when the timer was first started.
  /// - isRunning: A boolean flag indicating if the timer is currently running.
  /// - infusionData: A map containing the infusion characteristics as the key and the infusion duration in seconds at that rate as the value.
  InfusionStopwatchTimer.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        characteristics = InfusionCharacteristics.fromJson(json['characteristics']),
        infusedVolume = json['infusedVolume'],
        durationInSeconds = Duration(seconds: json['durationInSeconds']),
        remainingSeconds = Duration(seconds: json['remainingSeconds']),
        firstStartTime = json['firstStartTime'] != null ? DateTime.parse(json['firstStartTime']) : null,
        _isRunning = json['isRunning'],
        _infusionData = json['infusionData'].map((key, value) => MapEntry(InfusionCharacteristics.fromJson(key), Duration(seconds: value)));

  /// Converts the timer's state to a map of data.
  ///
  /// This method is called when the app is closed. It converts the timer's state to a map of data
  /// that can be stored in a database or file. The data map contains the following:
  /// - id: The timer's unique identifier.
  /// - title: The title of the timer.
  /// - characteristics: The infusion characteristics of the timer.
  /// - infusedVolume: The volume of the IV fluid that has been infused.
  /// - durationInSeconds: The total duration of the infusion in seconds.
  /// - remainingSeconds: The remaining duration of the infusion in seconds.
  /// - firstStartTime: The time when the timer was first started.
  /// - isRunning: A boolean flag indicating if the timer is currently running.
  /// - infusionData: A map containing the infusion characteristics as the key and the infusion duration in seconds at that rate as the value.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'characteristics': characteristics.toJson(),
      'infusedVolume': infusedVolume,
      'durationInSeconds': durationInSeconds!.inSeconds,
      'remainingSeconds': remainingSeconds!.inSeconds,
      'firstStartTime': firstStartTime?.toIso8601String(),
      'isRunning': _isRunning,
      'infusionData': _infusionData.map((key, value) => MapEntry(key.toJson(), value.inSeconds)),
    };
  }

  /// Ensures that the timer's periodic timer is running.
  ///
  /// This method checks if the timer is running and if the periodic timer is not already running.
  /// If the timer is running and the periodic timer is not running, it starts the periodic timer.
  void _ensureTimerIsRunning() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      _infusionData[characteristics] = Duration(seconds: _infusionData[characteristics]!.inSeconds + 1);
      _calculateRemainingSeconds();

      if (remainingSeconds!.inSeconds <= 0 && infusedVolume! >= characteristics.volume) {
        stop();
      }
    });
  }

  /// Starts the stopwatch timer if it is not already running.
  ///
  /// This method sets the `isRunning` flag to true and ensures that the characteristics exists in the infusion data map.
  /// It then starts a periodic timer that increments the infusion data's duration by one second
  /// every second. It also calculates the remaining seconds and stops the timer if the remaining
  /// seconds are less than or equal to zero.
  void start() {
    if (!_isRunning) {
      firstStartTime ??= DateTime.now();
      _isRunning = true;
      _ensureInfusionDataEntryExists();
      _ensureTimerIsRunning();
    }
  }

  /// Stops the timer if it is currently running.
  ///
  /// This method checks if the timer is running, and if so, it sets the
  /// `isRunning` flag to false and cancels the timer.
  void stop() {
    if (_isRunning) {
      _isRunning = false;
      _timer?.cancel();
    }
  }

  /// Resets the stopwatch timer by stopping it, clearing the infusion data,
  /// and reinitializing the timer.
  void reset() {
    stop();

    _infusionData.clear();

    _initialize();
  }

  /// Changes the current characteristics and reinitializes the timer.
  /// The infused data is not cleared.
  ///
  /// This method updates the characteristics with the provided [newCharacteristics] and
  /// then calls the `_initialize` method to reinitialize the timer.
  /// This enables the end user to modify the characteristics of the infusion process
  /// and see the updated remaining time.
  ///
  /// Parameters:
  /// - [newCharacteristics]: The new characteristics value to be set.
  void changeCharacteristics(InfusionCharacteristics newCharacteristics) {
    characteristics = newCharacteristics;
    _initialize();
  }

  /// Initializes the stopwatch timer by ensuring the `characteristics` exist in the `infusionData` map,
  /// computing the infusion duration in seconds based on the given volume,
  /// and calculating the remaining seconds.
  void _initialize() {
    _ensureInfusionDataEntryExists();

    durationInSeconds = _computeInfusionDurationInSeconds(characteristics.volume);

    _calculateRemainingSeconds();
  }

  /// Ensures that the `characteristics` key exists in the `infusionData` map.
  /// If the `characteristics` key does not exist, it initializes it with a
  /// `Duration` of 0 seconds.
  void _ensureInfusionDataEntryExists() {
    if (!_infusionData.containsKey(characteristics)) {
      _infusionData[characteristics] = Duration(seconds: 0);
    }
  }

  /// Calculates the remaining seconds for the infusion process.
  ///
  /// This method computes the total infused volume by iterating over the
  /// `infusionData` entries and summing up the infused volume for each entry.
  /// It then calculates the remaining volume by subtracting the infused volume
  /// from the total volume. If the remaining volume is less than zero, it is
  /// set to zero. Finally, it computes the remaining infusion duration in
  /// seconds based on the remaining volume.
  /// This enables the end user to modify the flow rate of the infusion process
  /// and see the updated remaining time.
  void _calculateRemainingSeconds() {
    double remainingVolume;

    _calculateInfusedVolumemL();

    remainingVolume = characteristics.volume - infusedVolume!;

    if (remainingVolume < 0) {
      remainingVolume = 0;
    }

    remainingSeconds = _computeInfusionDurationInSeconds(remainingVolume);
  }

  /// Calculates the total infused volume in milliliters (mL) based on the
  /// infusion data entries and updates the `infusedVolume` variable.
  ///
  /// This method iterates through each entry in the `infusionData` map,
  /// computes the infused volume for each entry using the `_computeInfusedVolumeInmL`
  /// method, and accumulates the result.
  ///
  /// The `infusionData` map contains the infusion characteristics as the key and the infusion
  /// duration in seconds at that rate as the value. The `dropFactor` is used
  /// in the computation of the infused volume which indicates how many drips are required per mL of infusion.
  void _calculateInfusedVolumemL() {
    double result = 0;

    for (final entry in _infusionData.entries) {
      result += _computeInfusedVolumeInmL(entry.value.inSeconds, entry.key.flowRate, entry.key.dropFactor);
    }

    infusedVolume = result;
  }

  /// Computes the duration of the infusion in seconds based on the target volume.
  ///
  /// The formula used is:
  /// ((targetVolume * dropFactor) / flowRate) = time from volume to empty in minutes
  ///
  /// If the target volume is greater than 0, the duration is calculated and converted to seconds.
  /// Otherwise, the duration is set to 0 seconds.
  ///
  /// [targetVolume] The volume of the IV fluid to be infused in mL.
  /// Returns a [Duration] object representing the infusion duration in seconds.
  Duration _computeInfusionDurationInSeconds(double targetVolume) {
    if (targetVolume > 0) {
      return Duration(seconds: (((targetVolume * characteristics.dropFactor) / characteristics.flowRate) * 60).toInt());
    }

    return Duration(seconds: 0);
  }

  /// Computes the infused volume in mL given a set rate in gtts/min, a drop factor in gtts/mL and a duration in seconds at the given rate in gtts/min.
  ///
  /// The formula used is:
  /// ((secondsAtRategttsPerMin / 60) * (rateIngttsPerMin / gttsPermL)) = infused volume in mL
  ///
  /// If the secondsAtRategttsPerMin value is greater than 0, the volume in mL is calculated.
  /// Otherwise, the volume is set to 0mL.
  ///
  /// [secondsAtRategttsPerMin] The duration in seconds at the given rate in gtts/min.
  /// [rateIngttsPerMin] The rate of infusion in gtts/min.
  /// [gttsPermL] The drop factor in gtts/mL.
  /// Returns a [double] representing the infused volume in mL.
  double _computeInfusedVolumeInmL(int secondsAtRategttsPerMin, double rateIngttsPerMin, double gttsPermL) {
    if (secondsAtRategttsPerMin == 0) {
      return 0;
    }

    return (secondsAtRategttsPerMin / 60) * (rateIngttsPerMin / gttsPermL);
  }
}
