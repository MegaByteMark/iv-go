class InfusionCharacteristics {
  late double volume, dropFactor, flowRate;

  // Make sure the equality operations on this clas use the values of the fields
  // not the references to the objects themselves.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InfusionCharacteristics) return false;
    return volume == other.volume &&
        dropFactor == other.dropFactor &&
        flowRate == other.flowRate;
  }

  @override
  int get hashCode {
    return volume.hashCode ^
        dropFactor.hashCode ^
        flowRate.hashCode;
  }

  InfusionCharacteristics(this.volume, this.dropFactor, this.flowRate);
}