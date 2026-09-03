class SecuritySettingsEntity {
  const SecuritySettingsEntity({
    required this.isBiometricsEnabled,
    required this.hasMasterPasscode,
    this.autoLockDurationMinutes = 5,
  });

  final bool isBiometricsEnabled;
  final bool hasMasterPasscode;
  final int autoLockDurationMinutes;

  SecuritySettingsEntity copyWith({
    bool? isBiometricsEnabled,
    bool? hasMasterPasscode,
    int? autoLockDurationMinutes,
  }) {
    return SecuritySettingsEntity(
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      hasMasterPasscode: hasMasterPasscode ?? this.hasMasterPasscode,
      autoLockDurationMinutes:
          autoLockDurationMinutes ?? this.autoLockDurationMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecuritySettingsEntity &&
          runtimeType == other.runtimeType &&
          isBiometricsEnabled == other.isBiometricsEnabled &&
          hasMasterPasscode == other.hasMasterPasscode &&
          autoLockDurationMinutes == other.autoLockDurationMinutes;

  @override
  int get hashCode =>
      isBiometricsEnabled.hashCode ^
      hasMasterPasscode.hashCode ^
      autoLockDurationMinutes.hashCode;
}
