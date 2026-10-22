// ignore_for_file: prefer_initializing_formals

import '../../domain/entities/app_info_entity.dart';
import '../../domain/entities/vpn_status_entity.dart';
import 'app_blocker_event.dart';

export '../../domain/entities/vpn_status_entity.dart' show VpnStatus, VpnStatusInfo;

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
    List<AppInfoEntity> displayedApps = const <AppInfoEntity>[],
    this.page = 1,
    this.pageSize = 15,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.filter = AppBlockerFilter.all,
    this.actionErrorMessage,
    this.vpnStatus = VpnStatus.active,
    this.vpnStatusReason,
    this.activeBlockedCount,
  }) : _displayedApps = displayedApps;

  final List<AppInfoEntity> originalApps;
  final List<AppInfoEntity> filteredApps;
  final List<AppInfoEntity> _displayedApps;
  final int page;
  final int pageSize;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String searchQuery;
  final AppBlockerFilter filter;
  final String? actionErrorMessage;
  final VpnStatus vpnStatus;
  final String? vpnStatusReason;
  final int? activeBlockedCount;

  List<AppInfoEntity> get displayedApps =>
      _displayedApps.isEmpty && filteredApps.isNotEmpty
          ? List<AppInfoEntity>.unmodifiable(
              filteredApps.take(page * pageSize),
            )
          : _displayedApps;

  int get blockedAppsCount => originalApps.where((app) => app.isBlocked).length;
  int get allowedAppsCount => originalApps.where((app) => !app.isBlocked).length;
  int get effectiveBlockedCount =>
      (activeBlockedCount != null && activeBlockedCount! > 0)
          ? activeBlockedCount!
          : blockedAppsCount;
  bool get isFirewallActive =>
      vpnStatus == VpnStatus.active && effectiveBlockedCount > 0;

  AppBlockerLoaded copyWith({
    List<AppInfoEntity>? originalApps,
    List<AppInfoEntity>? filteredApps,
    List<AppInfoEntity>? displayedApps,
    int? page,
    int? pageSize,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? searchQuery,
    AppBlockerFilter? filter,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
    VpnStatus? vpnStatus,
    String? vpnStatusReason,
    bool clearVpnStatusReason = false,
    int? activeBlockedCount,
    bool clearActiveBlockedCount = false,
  }) {
    final updatedOriginal = originalApps ?? this.originalApps;
    final updatedFiltered = filteredApps ?? this.filteredApps;
    final updatedPage = page ?? this.page;
    final updatedPageSize = pageSize ?? this.pageSize;
    final updatedDisplayed = displayedApps ??
        (filteredApps != null
            ? List<AppInfoEntity>.unmodifiable(
                updatedFiltered.take(updatedPage * updatedPageSize),
              )
            : this.displayedApps);

    return AppBlockerLoaded(
      originalApps: updatedOriginal,
      filteredApps: updatedFiltered,
      displayedApps: updatedDisplayed,
      page: updatedPage,
      pageSize: updatedPageSize,
      hasReachedMax: hasReachedMax ??
          (updatedDisplayed.length >= updatedFiltered.length),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
      vpnStatus: vpnStatus ?? this.vpnStatus,
      vpnStatusReason: clearVpnStatusReason
          ? null
          : (vpnStatusReason ?? this.vpnStatusReason),
      activeBlockedCount: clearActiveBlockedCount
          ? null
          : (activeBlockedCount ?? this.activeBlockedCount),
    );
  }
}

class AppBlockerError extends AppBlockerState {
  const AppBlockerError(this.message);

  final String message;
}
