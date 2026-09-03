// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/check_usage_permission_usecase.dart';
import '../../domain/usecases/get_usage_analytics_usecase.dart';
import '../../domain/usecases/request_usage_permission_usecase.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc({
    required CheckUsagePermissionUseCase checkUsagePermission,
    required RequestUsagePermissionUseCase requestUsagePermission,
    required GetUsageAnalyticsUseCase getUsageAnalytics,
  })  : _checkUsagePermission = checkUsagePermission,
        _requestUsagePermission = requestUsagePermission,
        _getUsageAnalytics = getUsageAnalytics,
        super(const AnalyticsInitial()) {
    on<CheckAnalyticsPermissionEvent>(_onCheckPermission);
    on<RequestAnalyticsPermissionEvent>(_onRequestPermission);
    on<LoadAnalyticsEvent>(_onLoadAnalytics);
  }

  final CheckUsagePermissionUseCase _checkUsagePermission;
  final RequestUsagePermissionUseCase _requestUsagePermission;
  final GetUsageAnalyticsUseCase _getUsageAnalytics;

  Future<void> _onCheckPermission(
    CheckAnalyticsPermissionEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    final result = await _checkUsagePermission(const NoParams());
    await result.fold(
      (failure) async => emit(AnalyticsError(failure.message)),
      (hasPermission) async {
        if (hasPermission) {
          add(const LoadAnalyticsEvent());
        } else {
          emit(const AnalyticsPermissionRequired());
        }
      },
    );
  }

  Future<void> _onRequestPermission(
    RequestAnalyticsPermissionEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    await _requestUsagePermission(const NoParams());
  }

  Future<void> _onLoadAnalytics(
    LoadAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(const AnalyticsLoading());

    final permResult = await _checkUsagePermission(const NoParams());
    final hasPermission = permResult.getOrElse(() => false);
    if (!hasPermission) {
      emit(const AnalyticsPermissionRequired());
      return;
    }

    final result = await _getUsageAnalytics(
      GetUsageAnalyticsParams(event.timeRange),
    );

    result.fold(
      (failure) => emit(AnalyticsError(failure.message)),
      (summary) => emit(
        AnalyticsLoaded(
          summary: summary,
          selectedRange: event.timeRange,
        ),
      ),
    );
  }
}
