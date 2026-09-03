import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../domain_filter/domain/entities/blocked_domain_entity.dart';
import '../../../domain_filter/presentation/bloc/domain_filter_bloc.dart';
import '../../../domain_filter/presentation/bloc/domain_filter_event.dart';
import '../../../domain_filter/presentation/bloc/domain_filter_state.dart';
import '../../../domain_filter/presentation/widgets/add_domain_dialog.dart';
import '../../../schedule/domain/entities/schedule_entity.dart';
import '../../../schedule/presentation/bloc/schedule_bloc.dart';
import '../../../schedule/presentation/bloc/schedule_event.dart';
import '../../../schedule/presentation/bloc/schedule_state.dart';
import '../../../schedule/presentation/widgets/create_schedule_dialog.dart';
import '../../domain/entities/app_info_entity.dart';
import '../bloc/app_blocker_bloc.dart';
import '../bloc/app_blocker_event.dart';
import '../bloc/app_blocker_state.dart';
import '../widgets/netgate_header.dart';
import '../widgets/rule_filter_card.dart';
import 'app_discovery_page.dart';
import 'shield_settings_page.dart';
import 'usage_statistics_page.dart';

class AccessControlPage extends StatelessWidget {
  const AccessControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Colors.white,
          backgroundColor: AppColors.cardBackground,
          onRefresh: () async => _handleRefresh(context),
          child: Column(
            children: [
              NetgateHeader(
                category: 'NETGATE // SHIELD',
                title: 'Access Control',
                activeDashIndex: 0,
                //onBack: () => Navigator.of(context).maybePop(),
                trailingAction: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: 'Usage Statistics',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UsageStatisticsPage(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: 'Shield Settings',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ShieldSettingsPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<AppBlockerBloc, AppBlockerState>(
                  builder: (context, appState) {
                    return BlocBuilder<DomainFilterBloc, DomainFilterState>(
                      builder: (context, domainState) {
                        return BlocBuilder<ScheduleBloc, ScheduleState>(
                          builder: (context, scheduleState) {
                            return _buildContent(
                              context,
                              appState,
                              domainState,
                              scheduleState,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
          enableFeedback: true,
          backgroundColor: AppColors.cardBackground,
          isExtended: true,
          onPressed: (){ _showWeaveRuleOptions(context);}, label: Row(
        spacing: 10,
            children: [
              Icon(Icons.add,color: Colors.white,),
              Text("More Options",    textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textPrimary),),
            ],
          ),)
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppBlockerState appState,
    DomainFilterState domainState,
    ScheduleState scheduleState,
  ) {
    if (appState is AppBlockerInitial || appState is AppBlockerLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (appState is AppBlockerError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appState.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
                onPressed: () => context.read<AppBlockerBloc>().add(
                  const LoadInstalledAppsEvent(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final loaded = appState as AppBlockerLoaded;
    final apps = loaded.originalApps;

    final blockedApps = apps.where((app) => app.isBlocked).toList();
    final dormantApps = apps.where((app) => !app.isBlocked).toList();

    final allDomains = domainState is DomainFilterLoaded
        ? domainState.allDomains
        : <BlockedDomainEntity>[];
    final activeDomains = allDomains.where((d) => d.isBlocked).toList();
    final dormantDomains = allDomains.where((d) => !d.isBlocked).toList();

    final allSchedules = scheduleState is ScheduleLoaded
        ? scheduleState.allSchedules
        : <ScheduleEntity>[];
    final now = DateTime.now();
    final activeSchedules = allSchedules
        .where((s) => s.isEnabled && s.isCurrentlyActive(now))
        .toList();
    final dormantSchedules = allSchedules
        .where((s) => !s.isEnabled || !s.isCurrentlyActive(now))
        .toList();

    final totalActiveRules =
        blockedApps.length + activeDomains.length + activeSchedules.length;
    final totalDormantRules =
        dormantApps.length + dormantDomains.length + dormantSchedules.length;

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: AppColors.cardBackground,
      onRefresh: () async => _handleRefresh(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          // ACTIVE FILTERS SECTION
          _buildSectionHeader('ACTIVE FILTERS', '$totalActiveRules RULES'),
          const SizedBox(height: 12),
          if (blockedApps.isEmpty &&
              activeDomains.isEmpty &&
              activeSchedules.isEmpty)
            _buildEmptyState('No active filters.')
          else ...[
            ...activeSchedules.map((s) => _buildScheduleRuleItem(context, s)),
            ...blockedApps.map(
              (app) => _buildAppRuleItem(context, app, true, scheduleState),
            ),
            ...activeDomains
                .map((domain) => _buildDomainRuleItem(context, domain)),
          ],

          const SizedBox(height: 24),

          // DORMANT SECTION
          _buildSectionHeader('DORMANT', '$totalDormantRules RULES'),
          const SizedBox(height: 12),
          if (dormantApps.isEmpty &&
              dormantDomains.isEmpty &&
              dormantSchedules.isEmpty)
            _buildEmptyState('No dormant rules.')
          else ...[
            ...dormantSchedules.map((s) => _buildScheduleRuleItem(context, s)),
            ...dormantApps.map(
              (app) => _buildAppRuleItem(context, app, false, scheduleState),
            ),
            ...dormantDomains
                .map((domain) => _buildDomainRuleItem(context, domain)),
          ],
        ],
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    try {
      context.read<AppBlockerBloc>().add(const LoadInstalledAppsEvent());
      context.read<DomainFilterBloc>().add(const LoadDomainsEvent());
      context.read<ScheduleBloc>().add(const LoadSchedulesEvent());
      await context.read<AppBlockerBloc>().stream.firstWhere(
        (state) => state is! AppBlockerLoading,
      );
    } catch (_) {}
  }

  Widget _buildSectionHeader(String title, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.sectionHeader),
        Text(count, style: AppTextStyles.sectionCount),
      ],
    );
  }

  Widget _buildAppRuleItem(
    BuildContext context,
    AppInfoEntity app,
    bool isBlocked,
    ScheduleState scheduleState,
  ) {
    String scheduleLabel = 'ALWAYS';
    bool effectiveBlocked = isBlocked;

    if (scheduleState is ScheduleLoaded) {
      final matchedSchedule =
          scheduleState.getScheduleForPackage(app.packageName);
      if (matchedSchedule != null) {
        final now = DateTime.now();
        final inWindow = matchedSchedule.isCurrentlyActive(now);
        scheduleLabel = matchedSchedule.formattedTimeRange();
        effectiveBlocked = matchedSchedule.isEnabled && inWindow;
      }
    }

    final statusText = effectiveBlocked ? 'RESTRICTED' : 'UNFILTERED';
    final subtitle = '$scheduleLabel | $statusText';

    return RuleFilterCard(
      key: ValueKey(app.packageName),
      title: app.appName,
      subtitle: subtitle,
      isActive: effectiveBlocked,
      iconBytes: app.iconBytes,
      fallbackIcon: Icons.grid_view_rounded,
      onChanged: (newValue) {
        context.read<AppBlockerBloc>().add(
          ToggleAppBlockEvent(
            packageName: app.packageName,
            isBlocked: newValue,
          ),
        );
      },
    );
  }

  Widget _buildScheduleRuleItem(BuildContext context, ScheduleEntity schedule) {
    final now = DateTime.now();
    final isActive = schedule.isEnabled && schedule.isCurrentlyActive(now);
    final statusText = isActive ? 'ACTIVE RESTRICTION' : (schedule.isEnabled ? 'SCHEDULED' : 'PAUSED');
    final subtitle =
        '${schedule.formattedTimeRange()} (${schedule.formattedActiveDays()}) | $statusText';

    return Dismissible(
      key: ValueKey(schedule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF991B1B),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'DELETE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        context.read<ScheduleBloc>().add(DeleteScheduleEvent(schedule.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed schedule "${schedule.name}"'),
            backgroundColor: AppColors.cardBackground,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: RuleFilterCard(
        key: ValueKey('schedule_${schedule.id}'),
        title: schedule.name,
        subtitle: subtitle,
        isActive: schedule.isEnabled,
        fallbackIcon: Icons.schedule,
        onChanged: (newValue) {
          context.read<ScheduleBloc>().add(
            ToggleScheduleEvent(id: schedule.id, isEnabled: newValue),
          );
        },
      ),
    );
  }

  Widget _buildDomainRuleItem(
    BuildContext context,
    BlockedDomainEntity domain,
  ) {
    final statusText = domain.isBlocked ? 'RESTRICTED' : 'UNFILTERED';
    final subtitle = 'ALWAYS | $statusText (Swipe to delete)';

    return Dismissible(
      key: ValueKey(domain.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF991B1B),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'DELETE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        context.read<DomainFilterBloc>().add(RemoveDomainEvent(domain.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed domain rule "${domain.domain}"'),
            backgroundColor: AppColors.cardBackground,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: RuleFilterCard(
        key: ValueKey(domain.id),
        title: domain.domain,
        subtitle: subtitle,
        isActive: domain.isBlocked,
        fallbackIcon: Icons.language,
        onChanged: (newValue) {
          context.read<DomainFilterBloc>().add(
            ToggleDomainEvent(id: domain.id, isBlocked: newValue),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }

  void _showWeaveRuleOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.schedule, color: AppColors.accentBlue),
                title: const Text(
                  'Create Time-Based Schedule',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Restrict network access during custom time windows',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  CreateScheduleDialog.show(context);
                },
              ),
              const Divider(color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.white),
                title: const Text(
                  'Add Domain / URL Filter',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Drop specific domains or wildcards via DNS sinkhole',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  AddDomainDialog.show(context);
                },
              ),
              const Divider(color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.apps, color: Colors.white),
                title: const Text(
                  'Block Installed Applications',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Restrict network access for installed Android apps',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  final appBloc = context.read<AppBlockerBloc>();
                  final domainBloc = context.read<DomainFilterBloc>();
                  final scheduleBloc = context.read<ScheduleBloc>();
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: appBloc),
                          BlocProvider.value(value: domainBloc),
                          BlocProvider.value(value: scheduleBloc),
                        ],
                        child: const AppDiscoveryPage(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
