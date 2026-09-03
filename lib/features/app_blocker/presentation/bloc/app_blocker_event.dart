sealed class AppBlockerEvent {
  const AppBlockerEvent();
}

class LoadInstalledAppsEvent extends AppBlockerEvent {
  const LoadInstalledAppsEvent();
}

class ToggleAppBlockEvent extends AppBlockerEvent {
  const ToggleAppBlockEvent({
    required this.packageName,
    required this.isBlocked,
  });

  final String packageName;
  final bool isBlocked;
}

class SearchAppEvent extends AppBlockerEvent {
  const SearchAppEvent(this.query);

  final String query;
}

enum AppBlockerFilter { all, blocked, unblocked }

class FilterBlockedEvent extends AppBlockerEvent {
  const FilterBlockedEvent(this.filter);

  final AppBlockerFilter filter;
}
