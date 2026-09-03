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
  });

  final List<AppInfoEntity> originalApps;
  final List<AppInfoEntity> filteredApps;
  final String searchQuery;
  final AppBlockerFilter filter;

  AppBlockerLoaded copyWith({
    List<AppInfoEntity>? originalApps,
    List<AppInfoEntity>? filteredApps,
    String? searchQuery,
    AppBlockerFilter? filter,
  }) => AppBlockerLoaded(
    originalApps: originalApps ?? this.originalApps,
    filteredApps: filteredApps ?? this.filteredApps,
    searchQuery: searchQuery ?? this.searchQuery,
    filter: filter ?? this.filter,
  );
}

class AppBlockerError extends AppBlockerState {
  const AppBlockerError(this.message);

  final String message;
}
