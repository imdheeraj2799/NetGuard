import '../../domain/entities/blocked_domain_entity.dart';

class DomainFilterModel extends BlockedDomainEntity {
  const DomainFilterModel({
    required super.id,
    required super.domain,
    required super.isBlocked,
    required super.createdAt,
  });

  factory DomainFilterModel.fromJson(Map<String, dynamic> json) {
    return DomainFilterModel(
      id: json['id'] as String,
      domain: json['domain'] as String,
      isBlocked: json['isBlocked'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory DomainFilterModel.fromEntity(BlockedDomainEntity entity) {
    return DomainFilterModel(
      id: entity.id,
      domain: entity.domain,
      isBlocked: entity.isBlocked,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'domain': domain,
        'isBlocked': isBlocked,
        'createdAt': createdAt.toIso8601String(),
      };

  BlockedDomainEntity toEntity() => BlockedDomainEntity(
        id: id,
        domain: domain,
        isBlocked: isBlocked,
        createdAt: createdAt,
      );

  @override
  DomainFilterModel copyWith({
    String? id,
    String? domain,
    bool? isBlocked,
    DateTime? createdAt,
  }) =>
      DomainFilterModel(
        id: id ?? this.id,
        domain: domain ?? this.domain,
        isBlocked: isBlocked ?? this.isBlocked,
        createdAt: createdAt ?? this.createdAt,
      );
}
