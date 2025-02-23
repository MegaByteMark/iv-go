import 'dart:async';

class StopwatchTimer {
  StopwatchTimer(this.id, this.volume, this.dropFactor, this.flowRate) {
    // Calculate the duration of the IV based on the volume, drop factor, and flow rate
    // ((volume * dropFactor) / flowRate) = time from volume to empty in minutes
    durationInSeconds = Duration(seconds: (((volume * dropFactor) / flowRate).ceil()) * 60);
    remainingSeconds = durationInSeconds;
  }

  //TODO - Add a method to calculate the amount infused based on the time elapsed
  //TODO - Add a method to handle changing the flow rate mid-infusion

  final int id;
  final double volume, dropFactor, flowRate;
  late Duration durationInSeconds, remainingSeconds;
  Timer? timer;
  bool isRunning = false;

  void start() {
    if (!isRunning) {
      isRunning = true;

      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds.inSeconds == 0) {
          stop();
        } else {
          remainingSeconds = Duration(seconds: remainingSeconds.inSeconds - 1);
        }
      });
    }
  }

  void stop() {
    if (isRunning) {
      isRunning = false;
      timer?.cancel();
    }
  }

  void reset() {
    stop();
    remainingSeconds = durationInSeconds;
  }
}
