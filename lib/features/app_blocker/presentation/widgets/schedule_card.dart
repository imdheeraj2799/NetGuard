import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/block_schedule_entity.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    required this.schedule,
    required this.isActiveNow,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final BlockScheduleEntity schedule;
  final bool isActiveNow;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String _getRecurrenceText() {
    switch (schedule.recurrence) {
      case ScheduleRecurrence.daily:
        return 'Every Day';
      case ScheduleRecurrence.weekdays:
        return 'Weekdays (Mon–Fri)';
      case ScheduleRecurrence.customDays:
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final activeDays = schedule.customDaysOfWeek
            .map((d) => (d >= 1 && d <= 7) ? days[d - 1] : '')
            .where((s) => s.isNotEmpty)
            .toList();
        return activeDays.isEmpty ? 'Custom Days' : activeDays.join(', ');
      case ScheduleRecurrence.oneTime:
        if (schedule.targetDate != null) {
          final date = schedule.targetDate!;
          final months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
          ];
          return 'One-Time: ${months[date.month - 1]} ${date.day}, ${date.year}';
        }
        return 'One-Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnforcing = schedule.isEnabled && isActiveNow;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnforcing
              ? AppColors.activeGreen.withValues(alpha: 0.6)
              : AppColors.cardBorder,
          width: isEnforcing ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title, Status Badge, Toggle Switch
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  schedule.name.trim().isEmpty
                                      ? 'Unnamed Schedule'
                                      : schedule.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isEnforcing) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A2F),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.activeGreen,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.fiber_manual_record,
                                        size: 8,
                                        color: AppColors.activeGreen,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Active Now',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.activeGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _getRecurrenceText(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: schedule.isEnabled,
                      activeTrackColor: AppColors.activeGreen,
                      activeThumbColor: AppColors.buttonPrimaryBackground,
                      inactiveTrackColor: AppColors.switchTrackInactive,
                      inactiveThumbColor: AppColors.switchThumbInactive,
                      onChanged: onToggle,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                // Middle Row: Time range and overnight badge
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatTime(schedule.startHour, schedule.startMinute)} – ${_formatTime(schedule.endHour, schedule.endMinute)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (schedule.isOvernight) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF28364F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🌙 Overnight',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFDE68A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Bottom Row: Apps count and actions (Edit / Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.apps_rounded,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${schedule.packageNames.length} ${schedule.packageNames.length == 1 ? 'App' : 'Apps'} Blocked',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppColors.textSecondary,
                          tooltip: 'Edit Schedule',
                          visualDensity: VisualDensity.compact,
                          onPressed: onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          color: const Color(0xFFF87171),
                          tooltip: 'Delete Schedule',
                          visualDensity: VisualDensity.compact,
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
