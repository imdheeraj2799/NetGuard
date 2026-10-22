import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/app_info_entity.dart';
import '../../domain/entities/block_schedule_entity.dart';
import '../bloc/app_blocker_bloc.dart';
import '../bloc/app_blocker_state.dart';
import '../bloc/schedule_bloc.dart';
import '../bloc/schedule_event.dart';
import '../bloc/schedule_state.dart';
import '../widgets/schedule_app_picker_dialog.dart';

class ScheduleFormPage extends StatefulWidget {
  const ScheduleFormPage({
    this.existingSchedule,
    super.key,
  });

  final BlockScheduleEntity? existingSchedule;

  @override
  State<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends State<ScheduleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late ScheduleRecurrence _recurrence;
  late Set<int> _customDays;
  DateTime? _oneTimeDate;

  late int _startHour;
  late int _startMinute;
  late int _endHour;
  late int _endMinute;

  late Set<String> _selectedPackageNames;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSchedule;
    if (existing != null) {
      _nameController = TextEditingController(text: existing.name);
      _recurrence = existing.recurrence;
      _customDays = Set<int>.from(existing.customDaysOfWeek);
      _oneTimeDate = existing.targetDate;
      _startHour = existing.startHour;
      _startMinute = existing.startMinute;
      _endHour = existing.endHour;
      _endMinute = existing.endMinute;
      _selectedPackageNames = Set<String>.from(existing.packageNames);
      _isEnabled = existing.isEnabled;
    } else {
      _nameController = TextEditingController();
      _recurrence = ScheduleRecurrence.daily;
      _customDays = {1, 2, 3, 4, 5}; // Mon-Fri default for custom
      _oneTimeDate = DateTime.now();
      _startHour = 9;
      _startMinute = 0;
      _endHour = 17;
      _endMinute = 0;
      _selectedPackageNames = {};
      _isEnabled = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isOvernight {
    final start = _startHour * 60 + _startMinute;
    final end = _endHour * 60 + _endMinute;
    return end < start;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _startHour, minute: _startMinute),
    );
    if (picked != null) {
      setState(() {
        _startHour = picked.hour;
        _startMinute = picked.minute;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _endHour, minute: _endMinute),
    );
    if (picked != null) {
      setState(() {
        _endHour = picked.hour;
        _endMinute = picked.minute;
      });
    }
  }

  Future<void> _pickOneTimeDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _oneTimeDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _oneTimeDate = picked);
    }
  }

  void _openAppPicker(List<AppInfoEntity> allApps, Map<String, String> assigned) async {
    final result = await ScheduleAppPickerDialog.show(
      context: context,
      allApps: allApps,
      initialSelectedPackages: _selectedPackageNames,
      assignedPackages: assigned,
    );
    if (result != null) {
      setState(() => _selectedPackageNames = result);
    }
  }

  void _saveSchedule() {
    if (_selectedPackageNames.isEmpty) {
      AppSnackBar.showWarning(
        context,
        'Please select at least one application to block.',
      );
      return;
    }

    if (_recurrence == ScheduleRecurrence.customDays && _customDays.isEmpty) {
      AppSnackBar.showWarning(
        context,
        'Please select at least one day for custom recurrence.',
      );
      return;
    }

    final now = DateTime.now();
    final id = widget.existingSchedule?.id ?? 'sched_${now.millisecondsSinceEpoch}';

    final schedule = BlockScheduleEntity(
      id: id,
      name: _nameController.text.trim().isEmpty
          ? 'Schedule'
          : _nameController.text.trim(),
      packageNames: _selectedPackageNames.toList(growable: false),
      recurrence: _recurrence,
      customDaysOfWeek: _recurrence == ScheduleRecurrence.customDays
          ? _customDays.toList(growable: false)
          : const [],
      targetDate: _recurrence == ScheduleRecurrence.oneTime ? _oneTimeDate : null,
      startHour: _startHour,
      startMinute: _startMinute,
      endHour: _endHour,
      endMinute: _endMinute,
      isEnabled: _isEnabled,
      createdAt: widget.existingSchedule?.createdAt ?? now,
      updatedAt: now,
    );

    context.read<ScheduleBloc>().add(SaveScheduleEvent(schedule));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSchedule != null;

    return BlocListener<ScheduleBloc, ScheduleState>(
      listener: (context, state) {
        if (state is ScheduleError) {
          AppSnackBar.showError(context, state.message);
        } else if (state is ScheduleLoaded && state.actionMessage != null) {
          AppSnackBar.showSuccess(context, state.actionMessage!);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            isEditing ? 'Edit Schedule' : 'New Block Schedule',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saveSchedule,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Schedule Name
              _buildSectionHeader('SCHEDULE NAME'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Work Focus, Night Sleep, Study Time',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardBackground,
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

              const SizedBox(height: 24),

              // Recurrence Section
              _buildSectionHeader('RECURRENCE'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildRecurrenceChip('Every Day', ScheduleRecurrence.daily),
                  _buildRecurrenceChip('Weekdays', ScheduleRecurrence.weekdays),
                  _buildRecurrenceChip('Custom Days', ScheduleRecurrence.customDays),
                  _buildRecurrenceChip('One-Time', ScheduleRecurrence.oneTime),
                ],
              ),

              // Custom Days selector
              if (_recurrence == ScheduleRecurrence.customDays) ...[
                const SizedBox(height: 12),
                _buildCustomDaysSelector(),
              ],

              // One-Time Date selector
              if (_recurrence == ScheduleRecurrence.oneTime) ...[
                const SizedBox(height: 12),
                _buildOneTimeDateTile(),
              ],

              const SizedBox(height: 24),

              // Time Range Section
              _buildSectionHeader('TIME RANGE'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeTile(
                      label: 'Start Time',
                      time: _formatTime(_startHour, _startMinute),
                      onTap: _pickStartTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeTile(
                      label: 'End Time',
                      time: _formatTime(_endHour, _endMinute),
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),

              // Overnight Banner
              if (_isOvernight) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF28364F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.nightlight_round,
                        size: 16,
                        color: Color(0xFFFDE68A),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Overnight schedule: Starts today and ends the following morning.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE0E7FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Applications Section
              BlocBuilder<AppBlockerBloc, AppBlockerState>(
                builder: (context, appState) {
                  final allApps = appState is AppBlockerLoaded
                      ? appState.originalApps
                      : <AppInfoEntity>[];

                  return BlocBuilder<ScheduleBloc, ScheduleState>(
                    builder: (context, schedState) {
                      final allAssigned = schedState is ScheduleLoaded
                          ? schedState.assignedPackages
                          : <String, String>{};
                      final assigned = Map<String, String>.from(allAssigned);
                      if (widget.existingSchedule != null) {
                        for (final pkg in widget.existingSchedule!.packageNames) {
                          assigned.remove(pkg);
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader('APPLICATIONS TO BLOCK'),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: Text(
                                  _selectedPackageNames.isEmpty
                                      ? 'Select Apps'
                                      : 'Change (${_selectedPackageNames.length})',
                                  style: const TextStyle(
                                    color: AppColors.accentBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () => _openAppPicker(allApps, assigned),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (_selectedPackageNames.isEmpty)
                            GestureDetector(
                              onTap: () => _openAppPicker(allApps, assigned),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.apps_rounded,
                                      size: 32,
                                      color: AppColors.textMuted,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No applications selected yet',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tap here to choose apps to restrict during this schedule',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedPackageNames.map((pkg) {
                                  final app = allApps
                                      .where((a) => a.packageName == pkg)
                                      .firstOrNull;
                                  final displayName = app?.appName ?? pkg;

                                  return Chip(
                                    backgroundColor: const Color(0xFF28364F),
                                    side: BorderSide.none,
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedPackageNames.remove(pkg);
                                      });
                                    },
                                    label: Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // Enable / Disable Switch Tile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Schedule',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enforce internet block rules when active',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: _isEnabled,
                      activeTrackColor: AppColors.activeGreen,
                      activeThumbColor: AppColors.buttonPrimaryBackground,
                      inactiveTrackColor: AppColors.switchTrackInactive,
                      inactiveThumbColor: AppColors.switchThumbInactive,
                      onChanged: (val) => setState(() => _isEnabled = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Save Schedule Primary Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimaryBackground,
                    foregroundColor: AppColors.buttonPrimaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveSchedule,
                  child: Text(
                    isEditing ? 'Update Schedule' : 'Create Schedule',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildRecurrenceChip(String label, ScheduleRecurrence recurrence) {
    final isSelected = _recurrence == recurrence;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _recurrence = recurrence);
        }
      },
      selectedColor: AppColors.accentBlue,
      backgroundColor: AppColors.cardBackground,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.buttonPrimaryText : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
      ),
    );
  }

  Widget _buildCustomDaysSelector() {
    final days = [
      {'val': 1, 'label': 'Mon'},
      {'val': 2, 'label': 'Tue'},
      {'val': 3, 'label': 'Wed'},
      {'val': 4, 'label': 'Thu'},
      {'val': 5, 'label': 'Fri'},
      {'val': 6, 'label': 'Sat'},
      {'val': 7, 'label': 'Sun'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final val = day['val'] as int;
        final label = day['label'] as String;
        final isSelected = _customDays.contains(val);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _customDays.remove(val);
              } else {
                _customDays.add(val);
              }
            });
          },
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentBlue : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.buttonPrimaryText
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOneTimeDateTile() {
    final date = _oneTimeDate ?? DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final formattedDate = '${months[date.month - 1]} ${date.day}, ${date.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pickOneTimeDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 10),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
