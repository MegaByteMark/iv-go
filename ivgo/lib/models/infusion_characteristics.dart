class InfusionCharacteristics {
  late double volume, dropFactor, flowRate;
  InfusionCharacteristics({this.volume = 0.0, this.dropFactor = 0.0, this.flowRate = 0.0});

  // Make sure the equality operations on this class use the values of the fields
  // not the references to the objects themselves.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InfusionCharacteristics) return false;
    return volume == other.volume && dropFactor == other.dropFactor && flowRate == other.flowRate;
  }

  @override
  int get hashCode {
    return volume.hashCode ^ dropFactor.hashCode ^ flowRate.hashCode;
  }

  Map<String, dynamic> toJson() {
    return {
      'volume': volume,
      'dropFactor': dropFactor,
      'flowRate': flowRate,
    };
  }

  InfusionCharacteristics.fromJson(Map<String, dynamic> json)
      : volume = json['volume'],
        dropFactor = json['dropFactor'],
        flowRate = json['flowRate'];
}
