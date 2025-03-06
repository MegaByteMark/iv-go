import 'dart:async';

class InfusionStopwatchTimer {
  InfusionStopwatchTimer(this.id, this.title, this.volume, this.dropFactor, this.flowRate) {
    _initialize();
  }

  final int id;
  final String title;
  final double volume, dropFactor;
  late double flowRate, infusedVolume;
  late Duration durationInSeconds, remainingSeconds;
  Timer? timer;
  bool isRunning = false;
  Map<double, Duration> infusionData = {};

  /// Starts the stopwatch timer if it is not already running.
  ///
  /// This method sets the `isRunning` flag to true and ensures that the flow rate exists in the infusion data map.
  /// It then starts a periodic timer that increments the infusion data's duration by one second
  /// every second. It also calculates the remaining seconds and stops the timer if the remaining
  /// seconds are less than or equal to zero.
  void start() {
    if (!isRunning) {
      isRunning = true;
      _ensureFlowRateExists();

      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        infusionData[flowRate] = Duration(seconds: infusionData[flowRate]!.inSeconds + 1);
        _calculateRemainingSeconds();

        if (remainingSeconds.inSeconds <= 0) {
          stop();
        }
      });
    }
  }

  /// Stops the timer if it is currently running.
  ///
  /// This method checks if the timer is running, and if so, it sets the
  /// `isRunning` flag to false and cancels the timer.
  void stop() {
    if (isRunning) {
      isRunning = false;
      timer?.cancel();
    }
  }

  /// Resets the stopwatch timer by stopping it, clearing the infusion data,
  /// and reinitializing the timer.
  void reset() {
    stop();

    infusionData.clear();

    _initialize();
  }

  /// Changes the flow rate to the specified value and reinitializes the timer.
  ///
  /// This method updates the flow rate with the provided [newFlowRate] and
  /// then calls the `_initialize` method to reinitialize the timer.
  /// This enables the end user to modify the flow rate of the infusion process
  /// and see the updated remaining time.
  ///
  /// Parameters:
  /// - [newFlowRate]: The new flow rate value to be set.
  void changeFlowRate(double newFlowRate) {
    flowRate = newFlowRate;

    _initialize();
  }

  /// Initializes the stopwatch timer by ensuring the flow rate exists,
  /// computing the infusion duration in seconds based on the given volume,
  /// and calculating the remaining seconds.
  void _initialize() {
    _ensureFlowRateExists();

    durationInSeconds = _computeInfusionDurationInSeconds(volume);

    _calculateRemainingSeconds();
  }

  /// Ensures that the `flowRate` key exists in the `infusionData` map.
  /// If the `flowRate` key does not exist, it initializes it with a
  /// `Duration` of 0 seconds.
  void _ensureFlowRateExists() {
    if (!infusionData.containsKey(flowRate)) {
      infusionData[flowRate] = Duration(seconds: 0);
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

    remainingVolume = volume - infusedVolume;

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
  /// The `infusionData` map contains flowRate in gtts/min as the key and the infusion
  /// duration in seconds at that rate as the value. The `dropFactor` is used
  /// in the computation of the infused volume which indicates how many drips are required per mL of infusion.
  void _calculateInfusedVolumemL() {
    double result = 0;

    for (final entry in infusionData.entries) {
      result += _computeInfusedVolumeInmL(entry.value.inSeconds, entry.key, dropFactor);
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
      return Duration(seconds: (((targetVolume * dropFactor) / flowRate) * 60).toInt());
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
