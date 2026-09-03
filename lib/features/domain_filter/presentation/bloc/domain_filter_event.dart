abstract class DomainFilterEvent {
  const DomainFilterEvent();
}

class LoadDomainsEvent extends DomainFilterEvent {
  const LoadDomainsEvent();
}

class AddDomainEvent extends DomainFilterEvent {
  const AddDomainEvent(this.domain);

  final String domain;
}

class ToggleDomainEvent extends DomainFilterEvent {
  const ToggleDomainEvent({
    required this.id,
    required this.isBlocked,
  });

  final String id;
  final bool isBlocked;
}

class RemoveDomainEvent extends DomainFilterEvent {
  const RemoveDomainEvent(this.id);

  final String id;
}

class SearchDomainEvent extends DomainFilterEvent {
  const SearchDomainEvent(this.query);

  final String query;
}
