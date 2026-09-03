import '../../domain/entities/dns_resolver_entity.dart';

abstract class SystemControlsEvent {
  const SystemControlsEvent();
}

class LoadSystemControlsEvent extends SystemControlsEvent {
  const LoadSystemControlsEvent();
}

class SelectDnsResolverEvent extends SystemControlsEvent {
  const SelectDnsResolverEvent(this.resolver);

  final DnsResolverEntity resolver;
}

class SetCustomDnsIpEvent extends SystemControlsEvent {
  const SetCustomDnsIpEvent(this.ip);

  final String ip;
}
