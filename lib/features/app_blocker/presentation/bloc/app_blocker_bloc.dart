// Public constructor dependencies make composition explicit at the DI boundary.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_info_entity.dart';
import '../../domain/usecases/get_installed_apps_usecase.dart';
import '../../domain/usecases/get_vpn_status_usecase.dart';
import '../../domain/usecases/restart_vpn_usecase.dart';
import '../../domain/usecases/toggle_block_status_usecase.dart';
import '../../domain/usecases/watch_vpn_status_usecase.dart';
import 'app_blocker_event.dart';
import 'app_blocker_state.dart';

class AppBlockerBloc extends Bloc<AppBlockerEvent, AppBlockerState> {
  AppBlockerBloc({
    required GetInstalledAppsUseCase getInstalledApps,
    required ToggleBlockStatusUseCase toggleBlockStatus,
    GetVpnStatusUseCase? getVpnStatus,
    WatchVpnStatusUseCase? watchVpnStatus,
    RestartVpnUseCase? restartVpn,
  }) : _getInstalledApps = getInstalledApps,
       _toggleBlockStatus = toggleBlockStatus,
       _getVpnStatus = getVpnStatus,
       _watchVpnStatus = watchVpnStatus,
       _restartVpn = restartVpn,
       super(const AppBlockerInitial()) {
    on<LoadInstalledAppsEvent>(_onLoadInstalledApps);
    on<LoadMoreAppsEvent>(_onLoadMoreApps);
    on<ToggleAppBlockEvent>(_onToggleAppBlock);
    on<ToggleAppInternetAccessEvent>(_onToggleAppInternetAccess);
    on<SearchAppEvent>(_onSearchApp);
    on<FilterBlockedEvent>(_onFilterBlocked);
    on<ClearErrorMessageEvent>(_onClearErrorMessage);
    on<CheckVpnStatusEvent>(_onCheckVpnStatus);
    on<VpnStatusUpdatedEvent>(_onVpnStatusUpdated);
    on<RestartVpnEvent>(_onRestartVpn);
    on<SyncScheduleRestrictionsEvent>(_onSyncScheduleRestrictions);

    _initVpnStatusSubscription();
  }

  final GetInstalledAppsUseCase _getInstalledApps;
  final ToggleBlockStatusUseCase _toggleBlockStatus;
  final GetVpnStatusUseCase? _getVpnStatus;
  final WatchVpnStatusUseCase? _watchVpnStatus;
  final RestartVpnUseCase? _restartVpn;

  StreamSubscription<VpnStatusInfo>? _vpnStatusSubscription;
  Map<String, String>? _pendingAssignedPackages;

  void _initVpnStatusSubscription() {
    if (_watchVpnStatus != null) {
      _vpnStatusSubscription = _watchVpnStatus().listen(
        (info) {
          add(VpnStatusUpdatedEvent(
            status: info.status,
            reason: info.reason,
            blockedCount: info.blockedCount,
          ));
        },
        onError: (_) {},
      );
    }
  }

  @override
  Future<void> close() async {
    await _vpnStatusSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadInstalledApps(
    LoadInstalledAppsEvent event,
    Emitter<AppBlockerState> emit,
  ) async {
    emit(const AppBlockerLoading());
    final result = await _getInstalledApps(const NoParams());

    await result.fold(
      (failure) async => emit(AppBlockerError(failure.message)),
      (apps) async {
        apps = _applyScheduleRestrictions(apps, _pendingAssignedPackages);
        final hasBlocked = apps.any((app) => app.isBlocked);
        VpnStatus initialVpnStatus =
            hasBlocked ? VpnStatus.active : VpnStatus.inactive;
        String? initialVpnReason;
        int? activeBlockedCount;

        if (_getVpnStatus != null) {
          final vpnResult = await _getVpnStatus(const NoParams());
          vpnResult.fold(
            (_) {},
            (info) {
              if (info.blockedCount > 0) {
                activeBlockedCount = info.blockedCount;
                initialVpnStatus = info.status;
                initialVpnReason = info.reason;
              } else if (hasBlocked) {
                initialVpnStatus = info.status;
                initialVpnReason = info.reason;
              } else {
                initialVpnStatus = VpnStatus.inactive;
                initialVpnReason = null;
              }
            },
          );
        }

        emit(
          _loadedState(
            originalApps: apps,
            vpnStatus: initialVpnStatus,
            vpnStatusReason: initialVpnReason,
            activeBlockedCount: activeBlockedCount,
          ),
        );
      },
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

    final willHaveBlockedApps =
        optimisticallyUpdated.any((app) => app.isBlocked);
    final optimisticVpnStatus = !willHaveBlockedApps
        ? VpnStatus.inactive
        : VpnStatus.active;
    final optimisticReason =
        !willHaveBlockedApps ? null : (currentState.vpnStatus == VpnStatus.restarting ? null : currentState.vpnStatusReason);

    emit(
      _loadedState(
        originalApps: optimisticallyUpdated,
        searchQuery: currentState.searchQuery,
        filter: currentState.filter,
        page: currentState.page,
        pageSize: currentState.pageSize,
        vpnStatus: optimisticVpnStatus,
        vpnStatusReason: optimisticReason,
      ),
    );

    final result = await _toggleBlockStatus(
      ToggleBlockStatusParams(
        packageName: event.packageName,
        isBlocked: event.isBlocked,
      ),
    );

    await result.fold(
      (failure) async => emit(AppBlockerError(failure.message)),
      (_) async {
        final currentS = state;
        if (currentS is! AppBlockerLoaded) return;

        if (currentS.blockedAppsCount == 0 &&
            (currentS.activeBlockedCount == null || currentS.activeBlockedCount == 0)) {
          if (currentS.vpnStatus != VpnStatus.inactive || currentS.vpnStatusReason != null) {
            emit(currentS.copyWith(
              vpnStatus: VpnStatus.inactive,
              clearVpnStatusReason: true,
              clearActiveBlockedCount: true,
            ));
          }
          return;
        }

        if (_getVpnStatus != null) {
          final vpnResult = await _getVpnStatus(const NoParams());
          vpnResult.fold(
            (_) {},
            (info) {
              final s = state;
              if (s is AppBlockerLoaded) {
                final totalBlocked = info.blockedCount > 0
                    ? info.blockedCount
                    : s.blockedAppsCount;
                final effectiveStatus = (info.status == VpnStatus.active && totalBlocked == 0)
                    ? VpnStatus.inactive
                    : info.status;
                final effectiveReason = (totalBlocked == 0 && info.status != VpnStatus.restarting)
                    ? null
                    : info.reason;

                if (s.vpnStatus != effectiveStatus ||
                    s.vpnStatusReason != effectiveReason ||
                    s.activeBlockedCount != totalBlocked) {
                  emit(s.copyWith(
                    vpnStatus: effectiveStatus,
                    vpnStatusReason: effectiveReason,
                    activeBlockedCount: totalBlocked > 0 ? totalBlocked : null,
                    clearActiveBlockedCount: totalBlocked == 0,
                    clearVpnStatusReason: totalBlocked == 0 && info.status != VpnStatus.restarting,
                  ));
                }
              }
            },
          );
        }
      },
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
        vpnStatus: currentState.vpnStatus,
        vpnStatusReason: currentState.vpnStatusReason,
        activeBlockedCount: currentState.activeBlockedCount,
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
        vpnStatus: currentState.vpnStatus,
        vpnStatusReason: currentState.vpnStatusReason,
        activeBlockedCount: currentState.activeBlockedCount,
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

  Future<void> _onCheckVpnStatus(
    CheckVpnStatusEvent event,
    Emitter<AppBlockerState> emit,
  ) async {
    if (_getVpnStatus == null) return;
    final result = await _getVpnStatus(const NoParams());
    result.fold(
      (_) {},
      (info) {
        final currentState = state;
        if (currentState is AppBlockerLoaded) {
          final totalBlocked = info.blockedCount > 0
              ? info.blockedCount
              : currentState.blockedAppsCount;
          final effectiveStatus = (info.status == VpnStatus.active && totalBlocked == 0)
              ? VpnStatus.inactive
              : info.status;
          final effectiveReason = (totalBlocked == 0 && info.status != VpnStatus.restarting)
              ? null
              : info.reason;

          emit(currentState.copyWith(
            vpnStatus: effectiveStatus,
            vpnStatusReason: effectiveReason,
            activeBlockedCount: totalBlocked > 0 ? totalBlocked : null,
            clearActiveBlockedCount: totalBlocked == 0,
            clearVpnStatusReason: totalBlocked == 0 && info.status != VpnStatus.restarting,
          ));
        }
      },
    );
  }

  void _onVpnStatusUpdated(
    VpnStatusUpdatedEvent event,
    Emitter<AppBlockerState> emit,
  ) {
    final currentState = state;
    if (currentState is! AppBlockerLoaded) return;

    final VpnStatus status = event.status is VpnStatus
        ? event.status as VpnStatus
        : VpnStatus.fromString(event.status?.toString());

    final totalBlocked = event.blockedCount > 0
        ? event.blockedCount
        : currentState.blockedAppsCount;

    final effectiveStatus = (status == VpnStatus.active && totalBlocked == 0)
        ? VpnStatus.inactive
        : status;
    final effectiveReason = (totalBlocked == 0 && status != VpnStatus.restarting)
        ? null
        : event.reason;

    emit(currentState.copyWith(
      vpnStatus: effectiveStatus,
      vpnStatusReason: effectiveReason,
      activeBlockedCount: totalBlocked > 0 ? totalBlocked : null,
      clearActiveBlockedCount: totalBlocked == 0,
      clearVpnStatusReason: totalBlocked == 0 && status != VpnStatus.restarting,
    ));
  }

  Future<void> _onRestartVpn(
    RestartVpnEvent event,
    Emitter<AppBlockerState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AppBlockerLoaded) return;

    emit(currentState.copyWith(
      vpnStatus: VpnStatus.restarting,
      vpnStatusReason: 'Restarting firewall...',
      clearActionErrorMessage: true,
    ));

    if (_restartVpn != null) {
      final result = await _restartVpn(const NoParams());
      result.fold(
        (failure) {
          final s = state;
          if (s is AppBlockerLoaded) {
            emit(s.copyWith(
              vpnStatus: VpnStatus.inactive,
              vpnStatusReason: failure.message,
              actionErrorMessage: 'Failed to restart VPN: ${failure.message}',
            ));
          }
        },
        (_) {},
      );
    }
  }

  void _onSyncScheduleRestrictions(
    SyncScheduleRestrictionsEvent event,
    Emitter<AppBlockerState> emit,
  ) {
    _pendingAssignedPackages = event.assignedPackages;
    final currentState = state;
    if (currentState is! AppBlockerLoaded) return;

    final updatedOriginal = _applyScheduleRestrictions(
      currentState.originalApps,
      event.assignedPackages,
    );

    emit(
      _loadedState(
        originalApps: updatedOriginal,
        searchQuery: currentState.searchQuery,
        filter: currentState.filter,
        page: currentState.page,
        pageSize: currentState.pageSize,
        actionErrorMessage: currentState.actionErrorMessage,
        vpnStatus: currentState.vpnStatus,
        vpnStatusReason: currentState.vpnStatusReason,
        activeBlockedCount: currentState.activeBlockedCount,
      ),
    );
  }

  List<AppInfoEntity> _applyScheduleRestrictions(
    List<AppInfoEntity> apps,
    Map<String, String>? assignedPackages,
  ) {
    if (assignedPackages == null) return apps;
    return apps.map((app) {
      final scheduleName = assignedPackages[app.packageName];
      final isPart = scheduleName != null;
      if (app.isSchedulePart != isPart || app.whichSchedule != scheduleName) {
        return app.copyWith(
          isSchedulePart: isPart,
          whichSchedule: scheduleName,
          clearWhichSchedule: !isPart,
        );
      }
      return app;
    }).toList(growable: false);
  }

  AppBlockerLoaded _loadedState({
    required List<AppInfoEntity> originalApps,
    String searchQuery = '',
    AppBlockerFilter filter = AppBlockerFilter.all,
    int page = 1,
    int pageSize = 15,
    String? actionErrorMessage,
    VpnStatus vpnStatus = VpnStatus.active,
    String? vpnStatusReason,
    int? activeBlockedCount,
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
      vpnStatus: vpnStatus,
      vpnStatusReason: vpnStatusReason,
      activeBlockedCount: activeBlockedCount,
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
