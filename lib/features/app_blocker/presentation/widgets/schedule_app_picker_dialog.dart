import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/app_info_entity.dart';

class ScheduleAppPickerDialog extends StatefulWidget {
  const ScheduleAppPickerDialog({
    required this.allApps,
    required this.initialSelectedPackages,
    required this.assignedPackages,
    required this.onConfirmed,
    super.key,
  });

  final List<AppInfoEntity> allApps;
  final Set<String> initialSelectedPackages;
  final Map<String, String> assignedPackages;
  final ValueChanged<Set<String>> onConfirmed;

  static Future<Set<String>?> show({
    required BuildContext context,
    required List<AppInfoEntity> allApps,
    required Set<String> initialSelectedPackages,
    required Map<String, String> assignedPackages,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleAppPickerDialog(
        allApps: allApps,
        initialSelectedPackages: initialSelectedPackages,
        assignedPackages: assignedPackages,
        onConfirmed: (selected) => Navigator.of(ctx).pop(selected),
      ),
    );
  }

  @override
  State<ScheduleAppPickerDialog> createState() =>
      _ScheduleAppPickerDialogState();
}

class _ScheduleAppPickerDialogState extends State<ScheduleAppPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  late Set<String> _selectedPackages;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedPackages = Set<String>.from(widget.initialSelectedPackages);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppInfoEntity> get _filteredApps {
    if (_searchQuery.trim().isEmpty) return widget.allApps;
    final query = _searchQuery.toLowerCase().trim();
    return widget.allApps.where((app) {
      return app.appName.toLowerCase().contains(query) ||
          app.packageName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredApps;

    return Material(
      color: AppColors.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Applications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_selectedPackages.length} selected',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      final assignable = widget.allApps
                          .where((a) =>
                              !widget.assignedPackages
                                  .containsKey(a.packageName) ||
                              widget.initialSelectedPackages
                                  .contains(a.packageName))
                          .map((a) => a.packageName)
                          .toSet();

                      if (_selectedPackages.length >= assignable.length) {
                        _selectedPackages.clear();
                      } else {
                        _selectedPackages = assignable;
                      }
                    });
                  },
                  child: Text(
                    _selectedPackages.isNotEmpty
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search applications...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentBlue),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),

          // Applications List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No matching applications',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final app = filtered[index];
                      final isSelected =
                          _selectedPackages.contains(app.packageName);
                      final conflictingSchedule =
                          widget.assignedPackages[app.packageName];
                      final isCurrentScheduleApp =
                          widget.initialSelectedPackages.contains(app.packageName);
                      final isRestricted =
                          conflictingSchedule != null && !isCurrentScheduleApp;

                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.cardBorderSubtle,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (isRestricted) {
                                AppSnackBar.showWarning(
                                  context,
                                  'This application is already restricted',
                                );
                              } else {
                                setState(() {
                                  if (isSelected) {
                                    _selectedPackages.remove(app.packageName);
                                  } else {
                                    _selectedPackages.add(app.packageName);
                                  }
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isRestricted ? 0.5 : 1.0,
                                      child: app.iconBytes != null &&
                                              app.iconBytes!.isNotEmpty
                                          ? Image.memory(
                                              app.iconBytes!,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 40,
                                              height: 40,
                                              color: AppColors.iconBoxBackground,
                                              child: const Icon(
                                                Icons.shield_outlined,
                                                color: AppColors.textSecondary,
                                                size: 20,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                app.appName,
                                                style: TextStyle(
                                                  color: isRestricted
                                                      ? AppColors.textSecondary
                                                      : AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isRestricted) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF3B1818),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: const Color(0xFFDC2626),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.lock_rounded,
                                                      size: 10,
                                                      color: Color(0xFFF87171),
                                                    ),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Restricted',
                                                      style: TextStyle(
                                                        color: Color(0xFFF87171),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          app.packageName,
                                          style: TextStyle(
                                            color: isRestricted
                                                ? AppColors.textMuted
                                                    .withValues(alpha: 0.7)
                                                : AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isRestricted) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'In schedule: "$conflictingSchedule"',
                                            style: const TextStyle(
                                              color: Color(0xFFFCA5A5),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IgnorePointer(
                                    ignoring: isRestricted,
                                    child: Checkbox(
                                      value: isRestricted ? false : isSelected,
                                      activeColor: AppColors.accentBlue,
                                      checkColor: AppColors.buttonPrimaryText,
                                      onChanged: isRestricted
                                          ? null
                                          : (checked) {
                                              setState(() {
                                                if (checked == true) {
                                                  _selectedPackages
                                                      .add(app.packageName);
                                                } else {
                                                  _selectedPackages
                                                      .remove(app.packageName);
                                                }
                                              });
                                            },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Confirm Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimaryBackground,
                    foregroundColor: AppColors.buttonPrimaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => widget.onConfirmed(_selectedPackages),
                  child: Text(
                    'Confirm Selection (${_selectedPackages.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
