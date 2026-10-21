enum VpnStatus {
  active,
  restarting,
  inactive;

  static VpnStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'active' => VpnStatus.active,
      'restarting' => VpnStatus.restarting,
      _ => VpnStatus.inactive,
    };
  }
}

class VpnStatusInfo {
  const VpnStatusInfo({
    required this.status,
    this.reason,
    this.blockedCount = 0,
  });

  final VpnStatus status;
  final String? reason;
  final int blockedCount;

  factory VpnStatusInfo.fromMap(Map<dynamic, dynamic> map) {
    return VpnStatusInfo(
      status: VpnStatus.fromString(map['status'] as String?),
      reason: map['reason'] as String?,
      blockedCount: (map['blockedCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VpnStatusInfo &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          reason == other.reason &&
          blockedCount == other.blockedCount;

  @override
  int get hashCode => Object.hash(status, reason, blockedCount);
}
