import 'package:ivgo/domain/infusion_characteristics.dart';

enum InfusionTimerStatus { paused, running, ended, recoveredOverdue }

/// Tracks the progress and restore state of a single infusion.
class InfusionTimer {
  final InfusionCharacteristics _initialCharacteristics;
  final DateTime Function() _nowProvider;
  final List<_InfusionPhase> _phases;

  int id;
  String title;
  InfusionCharacteristics characteristics;
  InfusionTimerStatus _status;
  DateTime? _lastStartedAt;
  DateTime? _completedAt;

  double infusedVolume = 0;
  Duration durationInSeconds = Duration.zero;
  Duration remainingSeconds = Duration.zero;

  bool get isRunning => _status == InfusionTimerStatus.running;
  bool get isPaused => _status == InfusionTimerStatus.paused;
  bool get isEnded => _status == InfusionTimerStatus.ended || _status == InfusionTimerStatus.recoveredOverdue;
  bool get isRecoveredOverdue => _status == InfusionTimerStatus.recoveredOverdue;
  InfusionTimerStatus get status => _status;
  DateTime? get completedAt => _completedAt;

  InfusionTimer(
    this.id,
    this.title,
    InfusionCharacteristics characteristics, {
    DateTime Function()? nowProvider,
  })  : characteristics = _cloneCharacteristics(characteristics),
        _initialCharacteristics = _cloneCharacteristics(characteristics),
        _nowProvider = nowProvider ?? DateTime.now,
        _status = InfusionTimerStatus.paused,
        _phases = <_InfusionPhase>[] {
    _refreshComputedFields();
  }

  InfusionTimer.fromJson(
    Map<String, dynamic> json, {
    DateTime Function()? nowProvider,
  })  : id = json['id'] as int,
        title = json['title'] as String,
        characteristics = InfusionCharacteristics.fromJson(
          json['characteristics'] as Map<String, dynamic>,
        ),
        _initialCharacteristics = json['initialCharacteristics'] != null
            ? InfusionCharacteristics.fromJson(
                json['initialCharacteristics'] as Map<String, dynamic>,
              )
            : InfusionCharacteristics.fromJson(
                json['characteristics'] as Map<String, dynamic>,
              ),
        _nowProvider = nowProvider ?? DateTime.now,
        _status = _statusFromJson(json),
        _lastStartedAt = _parseDateTime(
          json['lastStartedAt'] ?? json['firstStartTime'],
        ),
        _completedAt = _parseDateTime(json['completedAt']),
        _phases = _parsePhases(json) {
    _refreshComputedFields();
  }

  void onRestore() {
    reconcile(markRecoveredOverdue: true);
  }

  Map<String, dynamic> toJson() {
    reconcile();

    return {
      'id': id,
      'title': title,
      'characteristics': characteristics.toJson(),
      'initialCharacteristics': _initialCharacteristics.toJson(),
      'status': _status.name,
      'lastStartedAt': _lastStartedAt?.toIso8601String(),
      'completedAt': _completedAt?.toIso8601String(),
      'phases': _phases.map((phase) => phase.toJson()).toList(),
    };
  }

  void reconcile({DateTime? now, bool markRecoveredOverdue = false}) {
    _captureElapsed(
      now: now ?? _nowProvider(),
      markRecoveredOverdue: markRecoveredOverdue,
    );
    _refreshComputedFields();
  }

  void start() {
    if (isRunning || isEnded) {
      return;
    }

    _refreshComputedFields();

    if (remainingSeconds == Duration.zero) {
      return;
    }

    _status = InfusionTimerStatus.running;
    _completedAt = null;
    _lastStartedAt = _nowProvider();
  }

  void stop() {
    if (!isRunning) {
      return;
    }

    _captureElapsed(now: _nowProvider(), markRecoveredOverdue: false);

    if (!isEnded) {
      _status = InfusionTimerStatus.paused;
      _completedAt = null;
    }
  }

  void reset() {
    _status = InfusionTimerStatus.paused;
    _lastStartedAt = null;
    _completedAt = null;
    characteristics = _cloneCharacteristics(_initialCharacteristics);
    _phases.clear();
    _refreshComputedFields();
  }

  void acknowledgeRecoveredOverdue() {
    if (!isRecoveredOverdue) {
      return;
    }

    _status = InfusionTimerStatus.ended;
  }

  void changeCharacteristics(InfusionCharacteristics newCharacteristics) {
    final DateTime now = _nowProvider();
    final bool wasRunning = isRunning;

    if (wasRunning) {
      _captureElapsed(now: now, markRecoveredOverdue: false);
    } else {
      _refreshComputedFields();
    }

    characteristics = _cloneCharacteristics(newCharacteristics);

    if (infusedVolume >= characteristics.volume) {
      _markEnded(completedAt: _completedAt ?? now);
      return;
    }

    if (isEnded) {
      _status = InfusionTimerStatus.paused;
      _completedAt = null;
    }

    if (wasRunning) {
      _status = InfusionTimerStatus.running;
      _lastStartedAt = now;
    }

    _refreshComputedFields();
  }

  static InfusionTimerStatus _statusFromJson(Map<String, dynamic> json) {
    final dynamic rawStatus = json['status'];

    if (rawStatus is String) {
      try {
        return InfusionTimerStatus.values.byName(rawStatus);
      } catch (_) {
        // Fall back to legacy fields if the stored status is unknown.
      }
    }

    if (json['isRunning'] == true) {
      return InfusionTimerStatus.running;
    }

    return InfusionTimerStatus.paused;
  }

  static List<_InfusionPhase> _parsePhases(Map<String, dynamic> json) {
    final dynamic rawPhases = json['phases'];

    if (rawPhases is! List) {
      return <_InfusionPhase>[];
    }

    return rawPhases.map((phase) => _InfusionPhase.fromJson(phase as Map<String, dynamic>)).toList();
  }

  static DateTime? _parseDateTime(dynamic rawValue) {
    if (rawValue is String && rawValue.isNotEmpty) {
      return DateTime.parse(rawValue);
    }

    return null;
  }

  static InfusionCharacteristics _cloneCharacteristics(
    InfusionCharacteristics characteristics,
  ) {
    return InfusionCharacteristics(
      volume: characteristics.volume,
      dropFactor: characteristics.dropFactor,
      flowRate: characteristics.flowRate,
    );
  }

  void _captureElapsed({
    required DateTime now,
    required bool markRecoveredOverdue,
  }) {
    if (!isRunning || _lastStartedAt == null) {
      return;
    }

    final int elapsedSeconds = now.difference(_lastStartedAt!).inSeconds;

    if (elapsedSeconds <= 0) {
      return;
    }

    _refreshComputedFields();

    final double remainingVolume = characteristics.volume - infusedVolume;
    final int maxAdditionalSeconds = _computeInfusionDurationInSeconds(
      remainingVolume > 0 ? remainingVolume : 0,
    ).inSeconds;
    final int appliedSeconds = elapsedSeconds < maxAdditionalSeconds ? elapsedSeconds : maxAdditionalSeconds;

    if (appliedSeconds > 0) {
      _ensureCurrentPhase().elapsedSeconds += appliedSeconds;
      _lastStartedAt = _lastStartedAt!.add(Duration(seconds: appliedSeconds));
    }

    _refreshComputedFields();

    if (remainingSeconds == Duration.zero || infusedVolume >= characteristics.volume) {
      _markEnded(
        completedAt: _lastStartedAt ?? now,
        recoveredFromDowntime: markRecoveredOverdue,
      );
    }
  }

  _InfusionPhase _ensureCurrentPhase() {
    if (_phases.isEmpty || _phases.last.characteristics != characteristics) {
      _phases.add(
        _InfusionPhase(
          characteristics: _cloneCharacteristics(characteristics),
          elapsedSeconds: 0,
        ),
      );
    }

    return _phases.last;
  }

  void _markEnded({
    required DateTime completedAt,
    bool recoveredFromDowntime = false,
  }) {
    _status = recoveredFromDowntime ? InfusionTimerStatus.recoveredOverdue : InfusionTimerStatus.ended;
    _lastStartedAt = null;
    _completedAt = completedAt;
    _refreshComputedFields();
  }

  void _refreshComputedFields() {
    durationInSeconds = _computeInfusionDurationInSeconds(characteristics.volume);
    infusedVolume = _calculateInfusedVolumeMl();

    final double remainingVolume = characteristics.volume - infusedVolume;
    remainingSeconds = _computeInfusionDurationInSeconds(
      remainingVolume > 0 ? remainingVolume : 0,
    );
  }

  double _calculateInfusedVolumeMl() {
    double total = 0;

    for (final _InfusionPhase phase in _phases) {
      total += _computeInfusedVolumeInMl(
        phase.elapsedSeconds,
        phase.characteristics.flowRate,
        phase.characteristics.dropFactor,
      );
    }

    return total;
  }

  Duration _computeInfusionDurationInSeconds(double targetVolume) {
    if (targetVolume > 0) {
      return Duration(
        seconds: (((targetVolume * characteristics.dropFactor) / characteristics.flowRate) * 60).toInt(),
      );
    }

    return Duration.zero;
  }

  double _computeInfusedVolumeInMl(
    int secondsAtRateGttsPerMin,
    double rateInGttsPerMin,
    double gttsPerMl,
  ) {
    if (secondsAtRateGttsPerMin == 0) {
      return 0;
    }

    return (secondsAtRateGttsPerMin / 60) * (rateInGttsPerMin / gttsPerMl);
  }
}

class _InfusionPhase {
  _InfusionPhase({required this.characteristics, required this.elapsedSeconds});

  final InfusionCharacteristics characteristics;
  int elapsedSeconds;

  factory _InfusionPhase.fromJson(Map<String, dynamic> json) {
    return _InfusionPhase(
      characteristics: InfusionCharacteristics.fromJson(
        json['characteristics'] as Map<String, dynamic>,
      ),
      elapsedSeconds: json['elapsedSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'characteristics': characteristics.toJson(),
      'elapsedSeconds': elapsedSeconds,
    };
  }
}
