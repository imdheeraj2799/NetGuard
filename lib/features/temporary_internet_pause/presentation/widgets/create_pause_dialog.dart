import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../app_blocker/domain/entities/app_info_entity.dart';
import '../../domain/entities/pause_duration_preset.dart';
import 'duration_chip_selector.dart';

class CreatePauseDialog extends StatefulWidget {
  const CreatePauseDialog({
    super.key,
    required this.installedApps,
    required this.onPauseCreated,
    this.preselectedApp,
  });

  final List<AppInfoEntity> installedApps;
  final void Function(AppInfoEntity app, Duration duration, bool isCustom)
      onPauseCreated;
  final AppInfoEntity? preselectedApp;

  @override
  State<CreatePauseDialog> createState() => _CreatePauseDialogState();
}

class _CreatePauseDialogState extends State<CreatePauseDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customMinutesController =
      TextEditingController(text: '45');

  AppInfoEntity? _selectedApp;
  PauseDurationPreset _selectedPreset = PauseDurationPreset.fifteenMinutes;
  Duration _customDuration = const Duration(minutes: 45);
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedApp = widget.preselectedApp;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customMinutesController.dispose();
    super.dispose();
  }

  Duration get _effectiveDuration {
    if (_selectedPreset.isCustom) {
      return _customDuration;
    }
    return _selectedPreset.duration;
  }

  List<AppInfoEntity> get _filteredApps {
    if (_searchQuery.isEmpty) return widget.installedApps;
    return widget.installedApps
        .where((a) =>
            a.appName.toLowerCase().contains(_searchQuery) ||
            a.packageName.toLowerCase().contains(_searchQuery))
        .toList(growable: false);
  }

  void _showCustomDurationPicker() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text(
          'Custom Duration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter duration in minutes (1 – 1440):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customMinutesController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.iconBoxBackground,
                suffixText: 'mins',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFFBBF24)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBBF24),
              foregroundColor: const Color(0xFF141D2B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final val = int.tryParse(_customMinutesController.text.trim());
              if (val != null && val > 0 && val <= 1440) {
                setState(() {
                  _customDuration = Duration(minutes: val);
                  _selectedPreset = PauseDurationPreset.custom;
                });
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Set Duration',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pause_circle_outline_rounded,
                          color: Color(0xFFFBBF24), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Temporary Internet Pause',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.divider, height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Duration Picker Section
                  const Text(
                    'PAUSE DURATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DurationChipSelector(
                    selectedPreset: _selectedPreset,
                    customDuration: _customDuration,
                    onPresetSelected: (preset) {
                      if (preset.isCustom) {
                        _showCustomDurationPicker();
                      } else {
                        setState(() {
                          _selectedPreset = preset;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Selected App Indicator or App Selector
                  const Text(
                    'SELECT APPLICATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_selectedApp != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFBBF24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.iconBoxBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _selectedApp!.iconBytes != null &&
                                    _selectedApp!.iconBytes!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _selectedApp!.iconBytes!,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.apps_rounded,
                                    color: AppColors.accentBlue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedApp!.appName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _selectedApp!.packageName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedApp = null;
                              });
                            },
                            child: const Text('Change',
                                style: TextStyle(color: Color(0xFFFBBF24))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // App search field
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search installed applications...',
                        hintStyle: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textSecondary, size: 18),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFFBBF24)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _filteredApps.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching apps found',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredApps.length,
                              separatorBuilder: (_, _) => const Divider(
                                color: AppColors.cardBorderSubtle,
                                height: 1,
                              ),
                              itemBuilder: (ctx, idx) {
                                final app = _filteredApps[idx];
                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    dense: true,
                                    leading: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.iconBoxBackground,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: app.iconBytes != null &&
                                              app.iconBytes!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.memory(
                                                app.iconBytes!,
                                                width: 32,
                                                height: 32,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const Icon(Icons.apps_rounded,
                                              color: AppColors.textSecondary,
                                              size: 16),
                                    ),
                                    title: Text(
                                      app.appName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      app.packageName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    trailing: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 12,
                                        color: AppColors.textMuted),
                                    onTap: () {
                                      setState(() {
                                        _selectedApp = app;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('start_pause_button'),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text(
                  'Start Temporary Pause',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedApp != null
                      ? const Color(0xFFFBBF24)
                      : AppColors.iconBoxBackground,
                  foregroundColor: _selectedApp != null
                      ? const Color(0xFF141D2B)
                      : AppColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _selectedApp == null
                    ? null
                    : () {
                        widget.onPauseCreated(
                          _selectedApp!,
                          _effectiveDuration,
                          _selectedPreset.isCustom,
                        );
                        Navigator.of(context).pop();
                      },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
