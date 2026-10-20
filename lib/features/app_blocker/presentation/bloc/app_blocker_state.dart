import '../../domain/entities/app_info_entity.dart';
import 'app_blocker_event.dart';

sealed class AppBlockerState {
  const AppBlockerState();
}

class AppBlockerInitial extends AppBlockerState {
  const AppBlockerInitial();
}

class AppBlockerLoading extends AppBlockerState {
  const AppBlockerLoading();
}

class AppBlockerLoaded extends AppBlockerState {
  const AppBlockerLoaded({
    required this.originalApps,
    required this.filteredApps,
    this.searchQuery = '',
    this.filter = AppBlockerFilter.all,
    this.actionErrorMessage,
  });

  final List<AppInfoEntity> originalApps;
  final List<AppInfoEntity> filteredApps;
  final String searchQuery;
  final AppBlockerFilter filter;
  final String? actionErrorMessage;

  int get blockedAppsCount => originalApps.where((app) => app.isBlocked).length;
  int get allowedAppsCount => originalApps.where((app) => !app.isBlocked).length;
  bool get isFirewallActive => blockedAppsCount > 0;

  AppBlockerLoaded copyWith({
    List<AppInfoEntity>? originalApps,
    List<AppInfoEntity>? filteredApps,
    String? searchQuery,
    AppBlockerFilter? filter,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
  }) => AppBlockerLoaded(
    originalApps: originalApps ?? this.originalApps,
    filteredApps: filteredApps ?? this.filteredApps,
    searchQuery: searchQuery ?? this.searchQuery,
    filter: filter ?? this.filter,
    actionErrorMessage: clearActionErrorMessage
        ? null
        : (actionErrorMessage ?? this.actionErrorMessage),
  );
}

class AppBlockerError extends AppBlockerState {
  const AppBlockerError(this.message);

  final String message;
}
