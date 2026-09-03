// Public constructor dependencies make composition explicit at the DI boundary.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_info_entity.dart';
import '../../domain/usecases/get_installed_apps_usecase.dart';
import '../../domain/usecases/toggle_block_status_usecase.dart';
import 'app_blocker_event.dart';
import 'app_blocker_state.dart';

class AppBlockerBloc extends Bloc<AppBlockerEvent, AppBlockerState> {
  AppBlockerBloc({
    required GetInstalledAppsUseCase getInstalledApps,
    required ToggleBlockStatusUseCase toggleBlockStatus,
  }) : _getInstalledApps = getInstalledApps,
       _toggleBlockStatus = toggleBlockStatus,
       super(const AppBlockerInitial()) {
    on<LoadInstalledAppsEvent>(_onLoadInstalledApps);
    on<ToggleAppBlockEvent>(_onToggleAppBlock);
    on<SearchAppEvent>(_onSearchApp);
    on<FilterBlockedEvent>(_onFilterBlocked);
  }

  final GetInstalledAppsUseCase _getInstalledApps;
  final ToggleBlockStatusUseCase _toggleBlockStatus;

  Future<void> _onLoadInstalledApps(
    LoadInstalledAppsEvent event,
    Emitter<AppBlockerState> emit,
  ) async {
    emit(const AppBlockerLoading());
    final result = await _getInstalledApps(const NoParams());
    result.fold(
      (failure) => emit(AppBlockerError(failure.message)),
      (apps) => emit(_loadedState(originalApps: apps)),
    );
  }

  Future<void> _onToggleAppBlock(
    ToggleAppBlockEvent event,
    Emitter<AppBlockerState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AppBlockerLoaded) return;

    final optimisticallyUpdated = currentState.originalApps
        .map(
          (app) => app.packageName == event.packageName
              ? app.copyWith(isBlocked: event.isBlocked)
              : app,
        )
        .toList(growable: false);
    emit(
      _loadedState(
        originalApps: optimisticallyUpdated,
        searchQuery: currentState.searchQuery,
        filter: currentState.filter,
      ),
    );

    final result = await _toggleBlockStatus(
      ToggleBlockStatusParams(
        packageName: event.packageName,
        isBlocked: event.isBlocked,
      ),
    );
    result.fold((failure) => emit(AppBlockerError(failure.message)), (_) {});
  }

  void _onSearchApp(SearchAppEvent event, Emitter<AppBlockerState> emit) {
    final currentState = state;
    if (currentState is! AppBlockerLoaded) return;
    emit(
      _loadedState(
        originalApps: currentState.originalApps,
        searchQuery: event.query,
        filter: currentState.filter,
      ),
    );
  }

  void _onFilterBlocked(
    FilterBlockedEvent event,
    Emitter<AppBlockerState> emit,
  ) {
    final currentState = state;
    if (currentState is! AppBlockerLoaded) return;
    emit(
      _loadedState(
        originalApps: currentState.originalApps,
        searchQuery: currentState.searchQuery,
        filter: event.filter,
      ),
    );
  }

  AppBlockerLoaded _loadedState({
    required List<AppInfoEntity> originalApps,
    String searchQuery = '',
    AppBlockerFilter filter = AppBlockerFilter.all,
  }) => AppBlockerLoaded(
    originalApps: List.unmodifiable(originalApps),
    filteredApps: List.unmodifiable(
      originalApps.where((app) => _matches(app, searchQuery, filter)),
    ),
    searchQuery: searchQuery,
    filter: filter,
  );

  bool _matches(
    AppInfoEntity app,
    String searchQuery,
    AppBlockerFilter filter,
  ) {
    final query = searchQuery.trim().toLowerCase();
    final matchesQuery =
        query.isEmpty ||
        app.appName.toLowerCase().contains(query) ||
        app.packageName.toLowerCase().contains(query);
    final matchesFilter = switch (filter) {
      AppBlockerFilter.all => true,
      AppBlockerFilter.blocked => app.isBlocked,
      AppBlockerFilter.unblocked => !app.isBlocked,
    };
    return matchesQuery && matchesFilter;
  }
}
