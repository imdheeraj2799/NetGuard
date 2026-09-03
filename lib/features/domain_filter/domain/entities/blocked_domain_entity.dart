class BlockedDomainEntity {
  const BlockedDomainEntity({
    required this.id,
    required this.domain,
    required this.isBlocked,
    required this.createdAt,
  });

  final String id;
  final String domain;
  final bool isBlocked;
  final DateTime createdAt;

  BlockedDomainEntity copyWith({
    String? id,
    String? domain,
    bool? isBlocked,
    DateTime? createdAt,
  }) =>
      BlockedDomainEntity(
        id: id ?? this.id,
        domain: domain ?? this.domain,
        isBlocked: isBlocked ?? this.isBlocked,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockedDomainEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          domain == other.domain &&
          isBlocked == other.isBlocked &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, domain, isBlocked, createdAt);
}
