sealed class AppBlockerEvent {
  const AppBlockerEvent();
}

class LoadInstalledAppsEvent extends AppBlockerEvent {
  const LoadInstalledAppsEvent();

  @override
  bool operator ==(Object other) => other is LoadInstalledAppsEvent;

  @override
  int get hashCode => runtimeType.hashCode;
}

class ToggleAppBlockEvent extends AppBlockerEvent {
  const ToggleAppBlockEvent({
    required this.packageName,
    required this.isBlocked,
  });

  final String packageName;
  final bool isBlocked;

  @override
  bool operator ==(Object other) =>
      other is ToggleAppBlockEvent &&
      packageName == other.packageName &&
      isBlocked == other.isBlocked;

  @override
  int get hashCode => Object.hash(packageName, isBlocked);
}

class ToggleAppInternetAccessEvent extends AppBlockerEvent {
  const ToggleAppInternetAccessEvent({
    required this.packageName,
    required this.isInternetAllowed,
  });

  final String packageName;
  final bool isInternetAllowed;

  @override
  bool operator ==(Object other) =>
      other is ToggleAppInternetAccessEvent &&
      packageName == other.packageName &&
      isInternetAllowed == other.isInternetAllowed;

  @override
  int get hashCode => Object.hash(packageName, isInternetAllowed);
}

class SearchAppEvent extends AppBlockerEvent {
  const SearchAppEvent(this.query);

  final String query;

  @override
  bool operator ==(Object other) =>
      other is SearchAppEvent && query == other.query;

  @override
  int get hashCode => query.hashCode;
}

enum AppBlockerFilter { all, blocked, unblocked }

class FilterBlockedEvent extends AppBlockerEvent {
  const FilterBlockedEvent(this.filter);

  final AppBlockerFilter filter;

  @override
  bool operator ==(Object other) =>
      other is FilterBlockedEvent && filter == other.filter;

  @override
  int get hashCode => filter.hashCode;
}

class ClearErrorMessageEvent extends AppBlockerEvent {
  const ClearErrorMessageEvent();

  @override
  bool operator ==(Object other) => other is ClearErrorMessageEvent;

  @override
  int get hashCode => runtimeType.hashCode;
}
