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
    on<LoadMoreAppsEvent>(_onLoadMoreApps);
    on<ToggleAppBlockEvent>(_onToggleAppBlock);
    on<ToggleAppInternetAccessEvent>(_onToggleAppInternetAccess);
    on<SearchAppEvent>(_onSearchApp);
    on<FilterBlockedEvent>(_onFilterBlocked);
    on<ClearErrorMessageEvent>(_onClearErrorMessage);
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

  void _onLoadMoreApps(
    LoadMoreAppsEvent event,
    Emitter<AppBlockerState> emit,
  ) {
    final currentState = state;
    if (currentState is! AppBlockerLoaded) return;
    if (currentState.hasReachedMax || currentState.isLoadingMore) return;

    final nextPage = currentState.page + 1;
    final nextDisplayed = List<AppInfoEntity>.unmodifiable(
      currentState.filteredApps.take(nextPage * currentState.pageSize),
    );

    emit(
      currentState.copyWith(
        page: nextPage,
        displayedApps: nextDisplayed,
        hasReachedMax: nextDisplayed.length >= currentState.filteredApps.length,
      ),
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
        page: currentState.page,
        pageSize: currentState.pageSize,
      ),
    );

    final result = await _toggleBlockStatus(
      ToggleBlockStatusParams(
        packageName: event.packageName,
        isBlocked: event.isBlocked,
      ),
    );

    result.fold(
      (failure) => emit(AppBlockerError(failure.message)),
      (_) {},
    );
  }

  Future<void> _onToggleAppInternetAccess(
    ToggleAppInternetAccessEvent event,
    Emitter<AppBlockerState> emit,
  ) async {
    await _onToggleAppBlock(
      ToggleAppBlockEvent(
        packageName: event.packageName,
        isBlocked: !event.isInternetAllowed,
      ),
      emit,
    );
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

  void _onClearErrorMessage(
    ClearErrorMessageEvent event,
    Emitter<AppBlockerState> emit,
  ) {
    final currentState = state;
    if (currentState is! AppBlockerLoaded) return;
    emit(currentState.copyWith(clearActionErrorMessage: true));
  }

  AppBlockerLoaded _loadedState({
    required List<AppInfoEntity> originalApps,
    String searchQuery = '',
    AppBlockerFilter filter = AppBlockerFilter.all,
    int page = 1,
    int pageSize = 15,
    String? actionErrorMessage,
  }) {
    final filtered = List<AppInfoEntity>.unmodifiable(
      originalApps.where((app) => _matches(app, searchQuery, filter)),
    );
    final displayed = List<AppInfoEntity>.unmodifiable(
      filtered.take(page * pageSize),
    );

    return AppBlockerLoaded(
      originalApps: List<AppInfoEntity>.unmodifiable(originalApps),
      filteredApps: filtered,
      displayedApps: displayed,
      page: page,
      pageSize: pageSize,
      hasReachedMax: displayed.length >= filtered.length,
      searchQuery: searchQuery,
      filter: filter,
      actionErrorMessage: actionErrorMessage,
    );
  }

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
