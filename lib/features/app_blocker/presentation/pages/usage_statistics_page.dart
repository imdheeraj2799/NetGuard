import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../analytics/domain/entities/analytics_summary_entity.dart';
import '../../../analytics/domain/entities/analytics_time_range.dart';
import '../../../analytics/presentation/bloc/analytics_bloc.dart';
import '../../../analytics/presentation/bloc/analytics_event.dart';
import '../../../analytics/presentation/bloc/analytics_state.dart';
import '../widgets/netgate_header.dart';
import '../widgets/stat_metric_card.dart';
import '../widgets/top_app_usage_tile.dart';
import '../widgets/weekly_activity_chart.dart';

class UsageStatisticsPage extends StatefulWidget {
  const UsageStatisticsPage({super.key});

  @override
  State<UsageStatisticsPage> createState() => _UsageStatisticsPageState();
}

class _UsageStatisticsPageState extends State<UsageStatisticsPage>
    with WidgetsBindingObserver {
  AnalyticsTimeRange _selectedRange = AnalyticsTimeRange.week;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger fresh load on page open
    context.read<AnalyticsBloc>().add(LoadAnalyticsEvent(timeRange: _selectedRange));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permission and reload when returning from system settings
      context.read<AnalyticsBloc>().add(LoadAnalyticsEvent(timeRange: _selectedRange));
    }
  }

  void _onSelectRange(AnalyticsTimeRange range) {
    setState(() => _selectedRange = range);
    context.read<AnalyticsBloc>().add(LoadAnalyticsEvent(timeRange: range));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            NetgateHeader(
              category: 'NETGATE // ANALYTICS',
              title: 'Usage Statistics',
              activeDashIndex: 2,
              onBack: () => Navigator.of(context).pop(),
              trailingAction: PopupMenuButton<AnalyticsTimeRange>(
                icon: const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                color: AppColors.cardBackground,
                onSelected: _onSelectRange,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: AnalyticsTimeRange.day,
                    child: Text('Today', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: AnalyticsTimeRange.week,
                    child: Text('Last 7 Days', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: AnalyticsTimeRange.month,
                    child: Text('Last 30 Days', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            _buildTimeRangeTabs(),
            Expanded(
              child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
                builder: (context, state) {
                  if (state is AnalyticsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (state is AnalyticsPermissionRequired) {
                    return _buildPermissionBanner(context);
                  }

                  if (state is AnalyticsError) {
                    return _buildErrorState(context, state.message);
                  }

                  if (state is AnalyticsLoaded) {
                    return _buildLoadedContent(context, state.summary);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: AnalyticsTimeRange.values.map((range) {
          final isSelected = range == _selectedRange;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () => _onSelectRange(range),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentBlue
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentBlue
                          : AppColors.cardBorder,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    range.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isSelected ? Colors.black : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.security_outlined,
                size: 48,
                color: AppColors.accentBlue,
              ),
              const SizedBox(height: 16),
              const Text(
                'USAGE ACCESS REQUIRED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'To display live app screen time and Wi-Fi / Mobile data consumption, NetGuard needs Usage Access authorization in Android Settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AnalyticsBloc>().add(
                    const RequestAnalyticsPermissionEvent(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text(
                  'GRANT USAGE ACCESS',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  context.read<AnalyticsBloc>().add(
                    LoadAnalyticsEvent(timeRange: _selectedRange),
                  );
                },
                child: const Text(
                  'I ALREADY GRANTED PERMISSION (RELOAD)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<AnalyticsBloc>().add(
                  LoadAnalyticsEvent(timeRange: _selectedRange),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardBackground,
                foregroundColor: Colors.white,
              ),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    AnalyticsSummaryEntity summary,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // TOTAL TIME & DATA USED ROW
        Row(
          children: [
            StatMetricCard(
              label: 'Total Time',
              value: summary.formattedTotalScreenTime,
              trendText: _selectedRange.displayName,
              isIncrease: false,
            ),
            const SizedBox(width: 12),
            StatMetricCard(
              label: 'Data Used',
              value: summary.formattedTotalData,
              trendText: 'Wi-Fi + Mobile',
              isIncrease: true,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // WEEKLY ACTIVITY CHART
        WeeklyActivityChart(
          averageText: summary.formattedAverageDailyScreenTime,
          dayValues: summary.dailyActivityRatios.isEmpty
              ? const [0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05]
              : summary.dailyActivityRatios,
          dayLabels: summary.dailyLabels.isEmpty
              ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              : summary.dailyLabels,
        ),
        const SizedBox(height: 20),

        // TOP APPLICATIONS SECTION HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOP APPLICATIONS',
              style: AppTextStyles.sectionHeader,
            ),
            Text(
              '${summary.appUsages.length} APPS RECORDED',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // TOP APPS CARD LIST
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: summary.appUsages.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Text(
                      'No application usage recorded in this period.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(
                    summary.appUsages.length,
                    (index) {
                      final item = summary.appUsages[index];
                      final isLast = index == summary.appUsages.length - 1;
                      return Column(
                        children: [
                          TopAppUsageTile(
                            name: item.appName,
                            category: "",
                            time: item.formattedScreenTime,
                            dataUsage: item.formattedDataUsage,
                            icon: Icons.grid_view_rounded,
                          ),
                          if (!isLast)
                            const Divider(
                              color: AppColors.divider,
                              height: 1,
                              thickness: 1,
                              indent: 14,
                              endIndent: 14,
                            ),
                        ],
                      );
                    },
                  ),
                ),
        ),
        const SizedBox(height: 20),

        // CALLOUT BANNER
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF192437),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF263650),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  summary.appUsages.isNotEmpty
                      ? 'Live telemetry retrieved from Android UsageStats & NetworkStats.'
                      : 'Restriction rules active. Monitor screen time live as apps are used.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
