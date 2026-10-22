import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/block_schedule_entity.dart';
import '../../domain/services/schedule_engine.dart';
import '../bloc/schedule_bloc.dart';
import '../bloc/schedule_event.dart';
import '../bloc/schedule_state.dart';
import '../widgets/schedule_card.dart';
import 'schedule_form_page.dart';

class ScheduleListPage extends StatelessWidget {
  const ScheduleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    const engine = ScheduleEngine();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Block Schedules',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accentBlue),
            tooltip: 'Add Schedule',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ScheduleFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_schedule_fab'),
        backgroundColor: AppColors.buttonPrimaryBackground,
        foregroundColor: AppColors.buttonPrimaryText,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Schedule',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ScheduleFormPage(),
            ),
          );
        },
      ),
      body: BlocConsumer<ScheduleBloc, ScheduleState>(
        listener: (context, state) {
          if (state is ScheduleError) {
            AppSnackBar.showError(context, state.message);
          } else if (state is ScheduleLoaded && state.actionMessage != null) {
            AppSnackBar.showSuccess(context, state.actionMessage!);
          }
        },
        builder: (context, state) {
          if (state is ScheduleLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentBlue,
              ),
            );
          }

          final schedules = state is ScheduleLoaded
              ? state.schedules
              : (state is ScheduleError ? state.schedules : <BlockScheduleEntity>[]);
          final canScheduleExactAlarms = state is ScheduleLoaded
              ? state.canScheduleExactAlarms
              : (state is ScheduleError ? state.canScheduleExactAlarms : true);

          return RefreshIndicator(
            color: AppColors.buttonPrimaryText,
            backgroundColor: AppColors.cardBackground,
            onRefresh: () async {
              context.read<ScheduleBloc>().add(const LoadSchedulesEvent());
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96, top: 8),
              children: [
                // Exact Alarm Permission Warning Banner
                if (!canScheduleExactAlarms) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF382A0D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD97706),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFBBF24),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Exact Alarms Restricted',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFBBF24),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Grant permission so background block rules activate accurately on time.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFFDE68A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<ScheduleBloc>().add(
                                    const RequestExactAlarmPermissionEvent(),
                                  );
                            },
                            child: const Text(
                              'Enable',
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Schedules List or Empty State
                if (schedules.isEmpty)
                  _buildEmptyState(context)
                else
                  ...schedules.map((schedule) {
                    final isActiveNow = engine.isScheduleActiveAt(
                      schedule,
                      DateTime.now(),
                    );
                    return ScheduleCard(
                      schedule: schedule,
                      isActiveNow: isActiveNow,
                      onToggle: (enabled) {
                        context.read<ScheduleBloc>().add(
                              ToggleScheduleEvent(
                                id: schedule.id,
                                isEnabled: enabled,
                              ),
                            );
                      },
                      onEdit: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ScheduleFormPage(
                              existingSchedule: schedule,
                            ),
                          ),
                        );
                      },
                      onDelete: () => _confirmDelete(context, schedule),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.iconBoxBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 36,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Block Schedules Configured',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Automate internet blocking by creating schedules for work, sleep, or focus hours without manual switching.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimaryBackground,
                foregroundColor: AppColors.buttonPrimaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add Schedule',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ScheduleFormPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BlockScheduleEntity schedule) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text(
          'Delete Schedule?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${schedule.name.isEmpty ? 'this schedule' : schedule.name}"? Applications governed by this schedule will revert to manual firewall rules.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ScheduleBloc>().add(
                    DeleteScheduleEvent(schedule.id),
                  );
            },
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
