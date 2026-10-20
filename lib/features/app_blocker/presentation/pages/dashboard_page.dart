import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/app_blocker_bloc.dart';
import '../bloc/app_blocker_event.dart';
import '../bloc/app_blocker_state.dart';
import '../widgets/app_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<AppBlockerBloc, AppBlockerState>(
          listener: (context, state) {
            if (state is AppBlockerError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(0xFF991B1B),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () {
                      context.read<AppBlockerBloc>().add(
                        const LoadInstalledAppsEvent(),
                      );
                    },
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              color: Colors.white,
              backgroundColor: AppColors.cardBackground,
              onRefresh: () async {
                context.read<AppBlockerBloc>().add(
                  const LoadInstalledAppsEvent(),
                );
                await context.read<AppBlockerBloc>().stream.firstWhere(
                  (s) => s is! AppBlockerLoading,
                );
              },
              child: CustomScrollView(
                slivers: [
                  // App Bar / Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context, state),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: _buildSearchBar(context),
                  ),

                  // Firewall Status Summary
                  if (state is AppBlockerLoaded)
                    SliverToBoxAdapter(
                      child: _buildStatusSummary(state),
                    ),

                  // Main Content List / Loading / Error States
                  _buildContent(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppBlockerState state) {
    final isFirewallActive = state is AppBlockerLoaded && state.isFirewallActive;
    final blockedCount = state is AppBlockerLoaded ? state.blockedAppsCount : 0;

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

          // Firewall Status Indicator Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFirewallActive
                  ? const Color(0xFF1E3A2F)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFirewallActive
                    ? AppColors.activeGreen
                    : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFirewallActive
                      ? Icons.shield_rounded
                      : Icons.shield_outlined,
                  size: 16,
                  color: isFirewallActive
                      ? AppColors.activeGreen
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  isFirewallActive
                      ? '$blockedCount Blocked'
                      : 'All Allowed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFirewallActive
                        ? AppColors.activeGreen
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
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
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    context.read<AppBlockerBloc>().add(const SearchAppEvent(''));
                    setState(() {});
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

  Widget _buildContent(BuildContext context, AppBlockerState state) {
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
    final apps = loaded.filteredApps;

    if (apps.isEmpty) {
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

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 24, top: 4),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final app = apps[index];
            return AppCard(
              key: ValueKey(app.packageName),
              app: app,
              onInternetAccessChanged: (isAllowed) {
                context.read<AppBlockerBloc>().add(
                  ToggleAppBlockEvent(
                    packageName: app.packageName,
                    isBlocked: !isAllowed,
                  ),
                );
              },
            );
          },
          childCount: apps.length,
        ),
      ),
    );
  }
}
