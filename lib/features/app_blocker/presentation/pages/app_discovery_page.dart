import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../domain_filter/domain/entities/blocked_domain_entity.dart';
import '../../../domain_filter/presentation/bloc/domain_filter_bloc.dart';
import '../../../domain_filter/presentation/bloc/domain_filter_event.dart';
import '../../../domain_filter/presentation/bloc/domain_filter_state.dart';
import '../../domain/entities/app_info_entity.dart';
import '../bloc/app_blocker_bloc.dart';
import '../bloc/app_blocker_event.dart';
import '../bloc/app_blocker_state.dart';
import '../widgets/action_button.dart';
import '../widgets/discovery_app_tile.dart';
import '../widgets/netgate_header.dart';
import '../widgets/protocol_footer.dart';

class AppDiscoveryPage extends StatefulWidget {
  const AppDiscoveryPage({super.key});

  @override
  State<AppDiscoveryPage> createState() => _AppDiscoveryPageState();
}

class _AppDiscoveryPageState extends State<AppDiscoveryPage> {
  final _searchController = TextEditingController();
  final Set<String> _selectedPackages = {};
  final Set<String> _selectedDomains = {};

  final List<Map<String, String>> _frequentlyVisited = [
    {'domain': 'youtube.com', 'protocol': 'HTTPS'},
    {'domain': 'reddit.com', 'protocol': 'HTTP'},
    {'domain': 'github.com', 'protocol': 'HTTPS'},
    {'domain': 'twitter.com', 'protocol': 'HTTPS'},
    {'domain': 'twitch.tv', 'protocol': 'HTTPS'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize selected packages based on current blocked state
    try {
      final currentState = context.read<AppBlockerBloc>().state;
      if (currentState is AppBlockerLoaded) {
        for (final app in currentState.originalApps) {
          if (app.isBlocked) {
            _selectedPackages.add(app.packageName);
          }
        }
      }
    } catch (_) {}

    try {
      final domainState = context.read<DomainFilterBloc>().state;
      if (domainState is DomainFilterLoaded) {
        _selectedDomains.clear();
        for (final domain in domainState.allDomains) {
          if (domain.isBlocked) {
            _selectedDomains.add(domain.domain);
          }
        }
      }
    } catch (_) {}
  }

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
        child: BlocBuilder<AppBlockerBloc, AppBlockerState>(
          builder: (context, state) {
            return Column(
              children: [
                NetgateHeader(
                  category: 'NETGATE // DISCOVERY',
                  title: 'App & Site Discovery',
                  activeDashIndex: 1,
                  onBack: () => Navigator.of(context).pop(),
                  trailingAction: IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => context.read<AppBlockerBloc>().add(
                      const LoadInstalledAppsEvent(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildContent(context, state),
                ),
                _buildBottomBar(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (query) {
        context.read<AppBlockerBloc>().add(SearchAppEvent(query));
        setState(() {});
      },
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: const InputDecoration(
        hintText: 'Search installed apps or domains...',
        prefixIcon: Icon(Icons.search, size: 20),
        suffixIcon: Icon(Icons.tune, size: 20),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppBlockerState state) {
    if (state is AppBlockerInitial || state is AppBlockerLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (state is AppBlockerError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    final loaded = state as AppBlockerLoaded;
    final apps = loaded.filteredApps;

    // Filter frequently visited domains based on search
    final query = _searchController.text.trim().toLowerCase();
    final matchingDomains = _frequentlyVisited.where((site) {
      if (query.isEmpty) return true;
      return site['domain']!.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // INSTALLED APPLICATIONS
        _buildSectionHeader('INSTALLED APPLICATIONS', '${apps.length} FOUND'),
        const SizedBox(height: 12),
        if (apps.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No applications found',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ...apps.map((app) => _buildAppTile(app)),

        const SizedBox(height: 20),

        // FREQUENTLY VISITED
        _buildSectionHeader(
          'FREQUENTLY VISITED',
          '${matchingDomains.length} FOUND',
        ),
        const SizedBox(height: 12),
        ...matchingDomains.map((site) => _buildDomainTile(site)),
        const SizedBox(height: 16),
      ],
    );
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

  Widget _buildAppTile(AppInfoEntity app) {
    final isSelected = _selectedPackages.contains(app.packageName);

    return DiscoveryAppTile(
      key: ValueKey(app.packageName),
      title: app.appName,
      subtitle: "Dummy",
      iconBytes: app.iconBytes,
      isSelected: isSelected,
      onChanged: (selected) {
        setState(() {
          if (selected == true) {
            _selectedPackages.add(app.packageName);
          } else {
            _selectedPackages.remove(app.packageName);
          }
        });
      },
    );
  }

  Widget _buildDomainTile(Map<String, String> site) {
    final domain = site['domain']!;
    final protocol = site['protocol']!;
    final isSelected = _selectedDomains.contains(domain);

    return DiscoveryAppTile(
      key: ValueKey(domain),
      title: domain,
      subtitle: protocol,
      isDomain: true,
      isSelected: isSelected,
      onChanged: (selected) {
        setState(() {
          if (selected == true) {
            _selectedDomains.add(domain);
          } else {
            _selectedDomains.remove(domain);
          }
        });
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionButton(
            label: 'APPLY SELECTION',
            icon: Icons.check,
            onPressed: () {
              // Apply selections to the app blocker bloc
              final state = context.read<AppBlockerBloc>().state;
              if (state is AppBlockerLoaded) {
                for (final app in state.originalApps) {
                  final shouldBeBlocked = _selectedPackages.contains(
                    app.packageName,
                  );
                  if (app.isBlocked != shouldBeBlocked) {
                    context.read<AppBlockerBloc>().add(
                      ToggleAppBlockEvent(
                        packageName: app.packageName,
                        isBlocked: shouldBeBlocked,
                      ),
                    );
                  }
                }
              }

              // Apply selections to domain filter bloc
              try {
                final domainBloc = context.read<DomainFilterBloc>();
                final domainState = domainBloc.state;
                if (domainState is DomainFilterLoaded) {
                  for (final site in _frequentlyVisited) {
                    final domain = site['domain']!;
                    final shouldBeBlocked = _selectedDomains.contains(domain);
                    final existing = domainState.allDomains
                        .cast<BlockedDomainEntity?>()
                        .firstWhere(
                          (d) => d?.domain.toLowerCase() == domain.toLowerCase(),
                          orElse: () => null,
                        );
                    if (existing != null) {
                      if (existing.isBlocked != shouldBeBlocked) {
                        domainBloc.add(ToggleDomainEvent(
                          id: existing.id,
                          isBlocked: shouldBeBlocked,
                        ));
                      }
                    } else if (shouldBeBlocked) {
                      domainBloc.add(AddDomainEvent(domain));
                    }
                  }
                }
              } catch (_) {}

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selection applied successfully'),
                  backgroundColor: AppColors.cardBackground,
                  duration: Duration(seconds: 1),
                ),
              );
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 6),
          const ProtocolFooter(
            text: 'SASHIKO PROTOCOL ACTIVE',
            icon: Icons.close,
          ),
        ],
      ),
    );
  }
}
