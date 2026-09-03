class DnsResolverEntity {
  const DnsResolverEntity({
    required this.id,
    required this.name,
    required this.primaryIp,
    required this.secondaryIp,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String primaryIp;
  final String secondaryIp;
  final bool isCustom;

  static const cloudflare = DnsResolverEntity(
    id: 'cloudflare',
    name: 'Cloudflare',
    primaryIp: '1.1.1.1',
    secondaryIp: '1.0.0.1',
  );

  static const google = DnsResolverEntity(
    id: 'google',
    name: 'Google Public DNS',
    primaryIp: '8.8.8.8',
    secondaryIp: '8.8.4.4',
  );

  static const adguard = DnsResolverEntity(
    id: 'adguard',
    name: 'AdGuard DNS',
    primaryIp: '94.140.14.14',
    secondaryIp: '94.140.15.15',
  );

  static const predefined = [cloudflare, google, adguard];

  DnsResolverEntity copyWith({
    String? id,
    String? name,
    String? primaryIp,
    String? secondaryIp,
    bool? isCustom,
  }) {
    return DnsResolverEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryIp: primaryIp ?? this.primaryIp,
      secondaryIp: secondaryIp ?? this.secondaryIp,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DnsResolverEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          primaryIp == other.primaryIp &&
          isCustom == other.isCustom;

  @override
  int get hashCode => id.hashCode ^ primaryIp.hashCode ^ isCustom.hashCode;
}
