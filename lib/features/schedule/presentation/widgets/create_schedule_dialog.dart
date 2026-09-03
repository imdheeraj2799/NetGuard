import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../app_blocker/presentation/bloc/app_blocker_bloc.dart';
import '../../../app_blocker/presentation/bloc/app_blocker_state.dart';
import '../../domain/entities/schedule_entity.dart';
import '../bloc/schedule_bloc.dart';
import '../bloc/schedule_event.dart';

class CreateScheduleDialog extends StatefulWidget {
  const CreateScheduleDialog({super.key});

  static Future<void> show(BuildContext context) {
    final scheduleBloc = context.read<ScheduleBloc>();
    final appBlockerBloc = context.read<AppBlockerBloc>();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: scheduleBloc),
          BlocProvider.value(value: appBlockerBloc),
        ],
        child: const CreateScheduleDialog(),
      ),
    );
  }

  @override
  State<CreateScheduleDialog> createState() => _CreateScheduleDialogState();
}

class _CreateScheduleDialogState extends State<CreateScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Focus Hours');

  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0); // 10:00 PM
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0); // 07:00 AM
  final Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7}; // Everyday
  final Set<String> _selectedPackages = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatTime(TimeOfDay time) {
    final hour24 = time.hour;
    final min = time.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    return '${hour12.toString().padLeft(2, '0')}:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final startMin = _toMinutes(_startTime);
    final endMin = _toMinutes(_endTime);
    final isMidnightCrossover = startMin > endMin;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'WEAVE TIME SCHEDULE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Schedule Name
              Text('SCHEDULE NAME', style: AppTextStyles.categoryTag),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'e.g. Night Filter, Deep Work',
                  prefixIcon: Icon(Icons.schedule, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Schedule name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Time Pickers
              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerTile(
                      label: 'START TIME',
                      time: _startTime,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (picked != null) {
                          setState(() => _startTime = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimePickerTile(
                      label: 'END TIME',
                      time: _endTime,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (picked != null) {
                          setState(() => _endTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (isMidnightCrossover) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.accentBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.nightlight_round, size: 14, color: AppColors.accentBlue),
                      const SizedBox(width: 6),
                      Text(
                        'Overnight Window (Spans into next day)',
                        style: TextStyle(
                          color: AppColors.accentBlue.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Active Days Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ACTIVE DAYS', style: AppTextStyles.categoryTag),
                  Row(
                    children: [
                      _buildPresetChip('Mon-Fri', () {
                        setState(() => _selectedDays..clear()..addAll([1, 2, 3, 4, 5]));
                      }),
                      const SizedBox(width: 6),
                      _buildPresetChip('All', () {
                        setState(() => _selectedDays..clear()..addAll([1, 2, 3, 4, 5, 6, 7]));
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDayPill(1, 'M'),
                  _buildDayPill(2, 'T'),
                  _buildDayPill(3, 'W'),
                  _buildDayPill(4, 'T'),
                  _buildDayPill(5, 'F'),
                  _buildDayPill(6, 'S'),
                  _buildDayPill(7, 'S'),
                ],
              ),
              const SizedBox(height: 16),

              // Target Applications
              Text('TARGET APPLICATIONS', style: AppTextStyles.categoryTag),
              const SizedBox(height: 8),
              _buildAppSelector(),
              const SizedBox(height: 20),

              // Submit Action
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.buttonPrimaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'APPLY SCHEDULE RULE',
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerTile({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(time),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Icon(Icons.access_time, color: AppColors.accentBlue, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ),
    );
  }

  Widget _buildDayPill(int dayIndex, String label) {
    final isSelected = _selectedDays.contains(dayIndex);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            if (_selectedDays.length > 1) {
              _selectedDays.remove(dayIndex);
            }
          } else {
            _selectedDays.add(dayIndex);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAppSelector() {
    return BlocBuilder<AppBlockerBloc, AppBlockerState>(
      builder: (context, state) {
        if (state is! AppBlockerLoaded) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final apps = state.originalApps;
        if (apps.isEmpty) {
          return const Text('No installed applications found', style: TextStyle(color: AppColors.textSecondary, fontSize: 12));
        }

        return Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 140),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: ListView.builder(
            shrinkWrap: true,
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              final isChecked = _selectedPackages.contains(app.packageName);
              return CheckboxListTile(
                dense: true,
                value: isChecked,
                activeColor: AppColors.accentBlue,
                checkColor: Colors.black,
                title: Text(
                  app.appName,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                subtitle: Text(
                  app.packageName,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedPackages.add(app.packageName);
                    } else {
                      _selectedPackages.remove(app.packageName);
                    }
                  });
                },
              );
            },
          ),
        ),
      );
    },
  );
}

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one target application'),
          backgroundColor: AppColors.cardBackground,
        ),
      );
      return;
    }

    final newSchedule = ScheduleEntity(
      id: 'sched_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      startTimeMinutes: _toMinutes(_startTime),
      endTimeMinutes: _toMinutes(_endTime),
      activeDays: _selectedDays.toList()..sort(),
      targetPackages: _selectedPackages.toList(),
      isEnabled: true,
    );

    context.read<ScheduleBloc>().add(CreateScheduleEvent(newSchedule));
    Navigator.of(context).pop();
  }
}
