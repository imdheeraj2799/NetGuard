import '../../domain/entities/blocked_domain_entity.dart';

abstract class DomainFilterState {
  const DomainFilterState();
}

class DomainFilterInitial extends DomainFilterState {
  const DomainFilterInitial();
}

class DomainFilterLoading extends DomainFilterState {
  const DomainFilterLoading();
}

class DomainFilterLoaded extends DomainFilterState {
  const DomainFilterLoaded({
    required this.allDomains,
    required this.filteredDomains,
    this.searchQuery = '',
  });

  final List<BlockedDomainEntity> allDomains;
  final List<BlockedDomainEntity> filteredDomains;
  final String searchQuery;

  DomainFilterLoaded copyWith({
    List<BlockedDomainEntity>? allDomains,
    List<BlockedDomainEntity>? filteredDomains,
    String? searchQuery,
  }) {
    return DomainFilterLoaded(
      allDomains: allDomains ?? this.allDomains,
      filteredDomains: filteredDomains ?? this.filteredDomains,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainFilterLoaded &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          _listEquals(allDomains, other.allDomains) &&
          _listEquals(filteredDomains, other.filteredDomains);

  @override
  int get hashCode => Object.hash(allDomains, filteredDomains, searchQuery);

  static bool _listEquals(List<BlockedDomainEntity> a, List<BlockedDomainEntity> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class DomainFilterError extends DomainFilterState {
  const DomainFilterError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainFilterError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
