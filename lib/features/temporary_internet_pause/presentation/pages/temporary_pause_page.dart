import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../app_blocker/domain/entities/app_info_entity.dart';
import '../../../app_blocker/presentation/bloc/app_blocker_bloc.dart';
import '../../../app_blocker/presentation/bloc/app_blocker_state.dart';
import '../bloc/temporary_pause_bloc.dart';
import '../bloc/temporary_pause_event.dart';
import '../bloc/temporary_pause_state.dart';
import '../widgets/active_pause_card.dart';
import '../widgets/create_pause_dialog.dart';

class TemporaryPausePage extends StatelessWidget {
  const TemporaryPausePage({super.key, this.initialApp});

  final AppInfoEntity? initialApp;

  void _openCreatePauseSheet(BuildContext context, List<AppInfoEntity> apps) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreatePauseDialog(
        installedApps: apps,
        preselectedApp: initialApp,
        onPauseCreated: (app, duration, isCustom) {
          context.read<TemporaryPauseBloc>().add(
                CreateTemporaryPauseEvent(
                  packageName: app.packageName,
                  appName: app.appName,
                  duration: duration,
                  isCustom: isCustom,
                ),
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Temporary Internet Pause',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh Active Pauses',
            onPressed: () {
              context
                  .read<TemporaryPauseBloc>()
                  .add(const LoadTemporaryPausesEvent());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_temporary_pause_fab'),
        backgroundColor: const Color(0xFFFBBF24),
        foregroundColor: const Color(0xFF141D2B),
        icon: const Icon(Icons.timer_rounded),
        label: const Text(
          'Pause App (+)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          final appState = context.read<AppBlockerBloc>().state;
          final apps = appState is AppBlockerLoaded
              ? appState.originalApps
              : <AppInfoEntity>[];
          _openCreatePauseSheet(context, apps);
        },
      ),
      body: BlocConsumer<TemporaryPauseBloc, TemporaryPauseState>(
        listenWhen: (previous, current) {
          if (current is TemporaryPauseLoaded) {
            return current.actionMessage != null &&
                (previous is! TemporaryPauseLoaded ||
                    previous.actionMessage != current.actionMessage);
          }
          if (current is TemporaryPauseError) {
            return previous is! TemporaryPauseError ||
                previous.message != current.message;
          }
          return false;
        },
        listener: (context, state) {
          if (state is TemporaryPauseLoaded && state.actionMessage != null) {
            AppSnackBar.showSuccess(
              context,
              state.actionMessage!,
            );
            context
                .read<TemporaryPauseBloc>()
                .add(const ClearTemporaryPauseActionMessageEvent());
          } else if (state is TemporaryPauseError) {
            AppSnackBar.showError(
              context,
              state.message,
            );
          }
        },
        builder: (context, state) {
          if (state is TemporaryPauseInitial ||
              state is TemporaryPauseLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFBBF24),
              ),
            );
          }

          final pauses = state is TemporaryPauseLoaded
              ? state.pauses
              : (state is TemporaryPauseError ? state.pauses : []);

          if (pauses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.hourglass_empty_rounded,
                          size: 40,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Active Pauses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Temporarily pause internet access for distracting applications. Internet access automatically restores when the countdown finishes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBBF24),
                        foregroundColor: const Color(0xFF141D2B),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      label: const Text(
                        'Pause an App',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        final appState = context.read<AppBlockerBloc>().state;
                        final apps = appState is AppBlockerLoaded
                            ? appState.originalApps
                            : <AppInfoEntity>[];
                        _openCreatePauseSheet(context, apps);
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: pauses.length,
            itemBuilder: (context, index) {
              final pause = pauses[index];
              return ActivePauseCard(
                key: ValueKey(pause.id),
                pause: pause,
                onCancel: () {
                  context
                      .read<TemporaryPauseBloc>()
                      .add(CancelTemporaryPauseEvent(pause.id));
                },
              );
            },
          );
        },
      ),
    );
  }
}
