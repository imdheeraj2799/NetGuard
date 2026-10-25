import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/datasources/native_app_data_source.dart';
import '../../domain/entities/app_info_entity.dart';
import '../bloc/app_blocker_bloc.dart';
import '../bloc/app_blocker_event.dart';
import '../bloc/app_blocker_state.dart';
import '../bloc/schedule_bloc.dart';
import '../bloc/schedule_event.dart';
import '../bloc/schedule_state.dart';
import '../widgets/app_card.dart';
import 'schedule_list_page.dart';
import '../../../temporary_internet_pause/domain/entities/temporary_pause_entity.dart';
import '../../../temporary_internet_pause/presentation/bloc/temporary_pause_bloc.dart';
import '../../../temporary_internet_pause/presentation/bloc/temporary_pause_event.dart';
import '../../../temporary_internet_pause/presentation/bloc/temporary_pause_state.dart';
import '../../../temporary_internet_pause/presentation/pages/temporary_pause_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialNotificationRoute();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppBlockerBloc>().add(const CheckVpnStatusEvent());
      if (_hasTemporaryPauseBloc(context)) {
        context.read<TemporaryPauseBloc>().add(const ReconcileExpiredPausesEvent());
      }
      _checkInitialNotificationRoute();
    }
  }

  Future<void> _checkInitialNotificationRoute() async {
    try {
      if (!serviceLocator.isRegistered<NativeAppDataSource>()) return;
      final nativeDataSource = serviceLocator<NativeAppDataSource>();
      final payload = await nativeDataSource.getInitialNotificationPayload();
      if (payload != null && payload['route'] == 'schedule' && mounted) {
        _navigateToSchedules();
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (_isNearBottom) {
      context.read<AppBlockerBloc>().add(const LoadMoreAppsEvent());
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _navigateToSchedules() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ScheduleListPage(),
      ),
    );
    if (mounted) {
      context.read<AppBlockerBloc>().add(const CheckVpnStatusEvent());
      final schedState = context.read<ScheduleBloc>().state;
      if (schedState is ScheduleLoaded) {
        context.read<AppBlockerBloc>().add(
              SyncScheduleRestrictionsEvent(schedState.assignedPackages),
            );
      }
    }
  }

  Future<void> _navigateToTemporaryPause([AppInfoEntity? preselectedApp]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemporaryPausePage(initialApp: preselectedApp),
      ),
    );
    if (mounted) {
      context.read<AppBlockerBloc>().add(const CheckVpnStatusEvent());
      if (_hasTemporaryPauseBloc(context)) {
        context.read<TemporaryPauseBloc>().add(const LoadTemporaryPausesEvent());
      }
    }
  }

  bool _hasTemporaryPauseBloc(BuildContext context) {
    try {
      context.read<TemporaryPauseBloc>();
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _buildWithPauseState({
    required BuildContext context,
    required Widget Function(BuildContext context, TemporaryPauseState pauseState) builder,
  }) {
    if (_hasTemporaryPauseBloc(context)) {
      return BlocBuilder<TemporaryPauseBloc, TemporaryPauseState>(
        builder: builder,
      );
    }
    return builder(context, const TemporaryPauseLoaded(pauses: []));
  }

  String _formatPauseDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_schedule_button'),
        backgroundColor: AppColors.buttonPrimaryBackground,
        foregroundColor: AppColors.buttonPrimaryText,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text(
          'Add Schedule (+)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: _navigateToSchedules,
      ),
      body: SafeArea(
        bottom: false,
        child: MultiBlocListener(
          listeners: [
            BlocListener<ScheduleBloc, ScheduleState>(
              listener: (context, state) {
                if (state is ScheduleLoaded) {
                  context.read<AppBlockerBloc>().add(const CheckVpnStatusEvent());
                  context.read<AppBlockerBloc>().add(
                        SyncScheduleRestrictionsEvent(state.assignedPackages),
                      );
                }
              },
            ),
            BlocListener<AppBlockerBloc, AppBlockerState>(
              listener: (context, state) {
                if (state is AppBlockerLoaded) {
                  final schedState = context.read<ScheduleBloc>().state;
                  if (schedState is ScheduleLoaded) {
                    final assigned = schedState.assignedPackages;
                    final needsSync = state.originalApps.any((app) {
                      final sched = assigned[app.packageName];
                      return app.isSchedulePart != (sched != null) ||
                          app.whichSchedule != sched;
                    });
                    if (needsSync) {
                      context.read<AppBlockerBloc>().add(
                            SyncScheduleRestrictionsEvent(assigned),
                          );
                    }
                  }
                }
                if (state is AppBlockerError) {
                  AppSnackBar.showError(
                    context,
                    state.message,
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: AppColors.accentBlue,
                      onPressed: () {
                        context.read<AppBlockerBloc>().add(
                          const LoadInstalledAppsEvent(),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<ScheduleBloc, ScheduleState>(
            builder: (context, schedState) {
              return _buildWithPauseState(
                context: context,
                builder: (context, pauseState) {
                  return BlocBuilder<AppBlockerBloc, AppBlockerState>(
                    builder: (context, state) {
                      return RefreshIndicator(
                        color: Colors.white,
                        backgroundColor: AppColors.cardBackground,
                        onRefresh: () async {
                          context.read<ScheduleBloc>().add(
                            const LoadSchedulesEvent(),
                          );
                          context.read<AppBlockerBloc>().add(
                            const LoadInstalledAppsEvent(),
                          );
                          if (_hasTemporaryPauseBloc(context)) {
                            context.read<TemporaryPauseBloc>().add(
                              const LoadTemporaryPausesEvent(),
                            );
                          }
                          await context.read<AppBlockerBloc>().stream.firstWhere(
                            (s) => s is! AppBlockerLoading,
                          );
                        },
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            // App Bar / Header
                            SliverToBoxAdapter(
                              child: _buildHeader(context, state, schedState),
                            ),

                            // VPN Service Status & Alert Banner
                            if (state is AppBlockerLoaded)
                              SliverToBoxAdapter(
                                child: _buildVpnStatusCard(context, state, schedState),
                              ),

                            // Search Bar
                            SliverToBoxAdapter(
                              child: _buildSearchBar(context, state),
                            ),

                            // Firewall Status Summary
                            if (state is AppBlockerLoaded)
                              SliverToBoxAdapter(
                                child: _buildStatusSummary(state),
                              ),

                            // Main Content List / Loading / Error States
                            _buildContent(context, state, pauseState),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppBlockerState state, ScheduleState schedState) {
    final isFirewallActive = state is AppBlockerLoaded && state.isFirewallActive;
    final blockedCount = state is AppBlockerLoaded ? state.effectiveBlockedCount : 0;
    final vpnStatus = state is AppBlockerLoaded ? state.vpnStatus : VpnStatus.inactive;

    final String badgeText;
    final IconData badgeIcon;
    final Color badgeColor;
    final Color badgeBg;
    final Color badgeBorder;

    if (vpnStatus == VpnStatus.restarting && blockedCount > 0) {
      badgeText = 'Restarting';
      badgeIcon = Icons.sync_problem_rounded;
      badgeColor = const Color(0xFFFBBF24);
      badgeBg = const Color(0xFF382A0D);
      badgeBorder = const Color(0xFFD97706);
    } else if (vpnStatus == VpnStatus.inactive && blockedCount > 0) {
      badgeText = 'Inactive';
      badgeIcon = Icons.shield_outlined;
      badgeColor = const Color(0xFFF87171);
      badgeBg = const Color(0xFF3B1818);
      badgeBorder = const Color(0xFFDC2626);
    } else if (isFirewallActive) {
      badgeText = '$blockedCount Blocked';
      badgeIcon = Icons.shield_rounded;
      badgeColor = AppColors.activeGreen;
      badgeBg = const Color(0xFF1E3A2F);
      badgeBorder = AppColors.activeGreen;
    } else {
      badgeText = 'All Allowed';
      badgeIcon = Icons.shield_outlined;
      badgeColor = AppColors.textSecondary;
      badgeBg = AppColors.cardBackground;
      badgeBorder = AppColors.cardBorder;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NETGUARD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppColors.accentBlue,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Firewall Dashboard',
                style: AppTextStyles.screenTitle,
              ),
            ],
          ),

          // Header Actions & Firewall Status Indicator Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('header_temporary_pause_button'),
                icon: const Icon(Icons.timer_outlined, size: 22),
                color: const Color(0xFFFBBF24),
                tooltip: 'Temporary Internet Pause',
                visualDensity: VisualDensity.compact,
                onPressed: () => _navigateToTemporaryPause(),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: const Key('header_schedules_button'),
                icon: const Icon(Icons.schedule_rounded, size: 22),
                color: AppColors.accentBlue,
                tooltip: 'Internet Block Schedules',
                visualDensity: VisualDensity.compact,
                onPressed: _navigateToSchedules,
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      badgeIcon,
                      size: 16,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVpnStatusCard(BuildContext context, AppBlockerLoaded state, ScheduleState schedState) {
    final vpnStatus = state.vpnStatus;
    final isInactiveWithRules =
        vpnStatus == VpnStatus.inactive && state.effectiveBlockedCount > 0;
    final isRestarting =
        vpnStatus == VpnStatus.restarting && state.effectiveBlockedCount > 0;

    if (isInactiveWithRules || isRestarting) {
      final title = isRestarting
          ? 'Firewall Protection: Restarting'
          : 'Firewall Protection: Inactive';
      final reasonText = state.vpnStatusReason ??
          (isRestarting
              ? 'Attempting to re-establish VPN firewall rules...'
              : 'VPN service is inactive. Firewall rules are temporarily not enforced.');

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isRestarting
                ? const Color(0xFF261D0C)
                : const Color(0xFF2C1315),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRestarting
                  ? const Color(0xFFD97706)
                  : const Color(0xFFDC2626),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isRestarting
                        ? Icons.sync_rounded
                        : Icons.warning_amber_rounded,
                    color: isRestarting
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFF87171),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isRestarting
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFF87171),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isRestarting)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                reasonText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              if (!isRestarting) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(
                      'Restore Protection',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      context
                          .read<AppBlockerBloc>()
                          .add(const RestartVpnEvent());
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final enabledScheduleCount = schedState is ScheduleLoaded
        ? schedState.schedules.where((s) => s.isEnabled).length
        : 0;
    final hasEnabledSchedules = enabledScheduleCount > 0;

    final isActive =
        vpnStatus == VpnStatus.active && state.effectiveBlockedCount > 0;
    final statusLabel = isActive ? 'Active' : 'Inactive';
    final statusColor =
        isActive ? AppColors.activeGreen : AppColors.textSecondary;
    final statusSubtitle = isActive
        ? 'Enforcing firewall'
        : (hasEnabledSchedules
            ? '$enabledScheduleCount Schedule${enabledScheduleCount == 1 ? '' : 's'} Armed'
            : 'Idle');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'VPN Status: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
            const Spacer(),
            Text(
              statusSubtitle,
              style: TextStyle(
                fontSize: 11,
                color: hasEnabledSchedules && !isActive
                    ? AppColors.accentBlue
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, AppBlockerState state) {
    final hasSearchQuery =
        state is AppBlockerLoaded && state.searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (query) {
          context.read<AppBlockerBloc>().add(SearchAppEvent(query));
        },
        decoration: InputDecoration(
          hintText: 'Search installed applications...',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: hasSearchQuery
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    context.read<AppBlockerBloc>().add(
                      const SearchAppEvent(''),
                    );
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accentBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSummary(AppBlockerLoaded state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _buildMiniStat(
            label: 'INSTALLED',
            value: '${state.originalApps.length}',
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          _buildMiniStat(
            label: 'ALLOWED',
            value: '${state.allowedAppsCount}',
            color: AppColors.activeGreen,
          ),
          const SizedBox(width: 8),
          _buildMiniStat(
            label: 'BLOCKED',
            value: '${state.blockedAppsCount}',
            color: state.blockedAppsCount > 0
                ? const Color(0xFFF87171)
                : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppBlockerState state,
    TemporaryPauseState pauseState,
  ) {
    if (state is AppBlockerInitial || state is AppBlockerLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accentBlue),
              SizedBox(height: 16),
              Text(
                'Loading installed applications...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (state is AppBlockerError) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFF87171),
                  size: 48,
                ),
                const SizedBox(height: 14),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBackground,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  onPressed: () {
                    context.read<AppBlockerBloc>().add(
                      const LoadInstalledAppsEvent(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final loaded = state as AppBlockerLoaded;
    final apps = loaded.displayedApps;

    final activePausesMap = <String, TemporaryPauseEntity>{};
    if (pauseState is TemporaryPauseLoaded) {
      final now = pauseState.lastTick ?? DateTime.now();
      for (final p in pauseState.pauses) {
        if (!p.isExpired(now)) {
          activePausesMap[p.packageName] = p;
        }
      }
    }

    if (loaded.filteredApps.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                color: AppColors.textSecondary,
                size: 42,
              ),
              const SizedBox(height: 10),
              Text(
                loaded.searchQuery.isNotEmpty
                    ? 'No applications matching "${loaded.searchQuery}"'
                    : 'No launchable applications found',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasReachedMax = loaded.hasReachedMax;
    final itemCount = hasReachedMax ? apps.length : apps.length + 1;

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 24, top: 4),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= apps.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ),
              );
            }

            final app = apps[index];
            final isRestrictedBySchedule =
                app.isSchedulePart == true && app.whichSchedule != null;
            final activePause = activePausesMap[app.packageName];
            final isTemporarilyPaused = activePause != null;

            return AppCard(
              key: ValueKey(app.packageName),
              app: app,
              isTemporarilyPaused: isTemporarilyPaused,
              pauseRemainingText: activePause != null
                  ? _formatPauseDuration(activePause.remainingTime())
                  : null,
              onInternetAccessChanged: isTemporarilyPaused
                  ? (_) => _showTemporaryPauseRestrictedDialog(context, app, activePause)
                  : (isRestrictedBySchedule
                      ? (_) => _showScheduleRestrictedDialog(context, app)
                      : (isAllowed) {
                          context.read<AppBlockerBloc>().add(
                            ToggleAppBlockEvent(
                              packageName: app.packageName,
                              isBlocked: !isAllowed,
                            ),
                          );
                        }),
              onRestrictedTap: isTemporarilyPaused
                  ? () => _showTemporaryPauseRestrictedDialog(context, app, activePause)
                  : (isRestrictedBySchedule
                      ? () => _showScheduleRestrictedDialog(context, app)
                      : null),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }

  void _showScheduleRestrictedDialog(BuildContext context, AppInfoEntity app) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorderSubtle),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: AppColors.accentBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Schedule Restricted',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This application is part of a schedule, so you can't enable or disable it manually.",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (app.whichSchedule != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF0284C7), width: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_clock_rounded,
                      size: 12,
                      color: Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Assigned to: ${app.whichSchedule}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimaryBackground,
                foregroundColor: AppColors.buttonPrimaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTemporaryPauseRestrictedDialog(
    BuildContext context,
    AppInfoEntity app,
    TemporaryPauseEntity pause,
  ) {
    final remainingFormatted = _formatPauseDuration(pause.remainingTime());

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF382A0D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD97706)),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFFFBBF24),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Temporary Pause Active',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Internet access for this application is temporarily paused, so you can't enable or disable it manually.",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF382A0D),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD97706), width: 0.6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 12,
                    color: Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Temporarily paused: $remainingFormatted remaining',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimaryBackground,
                foregroundColor: AppColors.buttonPrimaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
