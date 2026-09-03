// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/dns_resolver_entity.dart';
import '../../domain/usecases/get_dns_settings_usecase.dart';
import '../../domain/usecases/set_dns_resolver_usecase.dart';
import 'system_controls_event.dart';
import 'system_controls_state.dart';

class SystemControlsBloc
    extends Bloc<SystemControlsEvent, SystemControlsState> {
  SystemControlsBloc({
    required GetDnsSettingsUseCase getDnsSettings,
    required SetDnsResolverUseCase setDnsResolver,
  })  : _getDnsSettings = getDnsSettings,
        _setDnsResolver = setDnsResolver,
        super(const SystemControlsInitial()) {
    on<LoadSystemControlsEvent>(_onLoadSystemControls);
    on<SelectDnsResolverEvent>(_onSelectDnsResolver);
    on<SetCustomDnsIpEvent>(_onSetCustomDnsIp);
  }

  final GetDnsSettingsUseCase _getDnsSettings;
  final SetDnsResolverUseCase _setDnsResolver;

  Future<void> _onLoadSystemControls(
    LoadSystemControlsEvent event,
    Emitter<SystemControlsState> emit,
  ) async {
    emit(const SystemControlsLoading());
    final result = await _getDnsSettings(NoParams());
    result.fold(
      (failure) => emit(SystemControlsError(failure.message)),
      (settings) => emit(
        SystemControlsLoaded(
          currentResolver: settings.currentResolver,
          availableResolvers: settings.availableResolvers,
        ),
      ),
    );
  }

  Future<void> _onSelectDnsResolver(
    SelectDnsResolverEvent event,
    Emitter<SystemControlsState> emit,
  ) async {
    final prev = state;
    final result = await _setDnsResolver(
      SetDnsResolverParams(resolver: event.resolver),
    );

    result.fold(
      (failure) => emit(SystemControlsError(failure.message)),
      (_) {
        if (prev is SystemControlsLoaded) {
          emit(
            SystemControlsLoaded(
              currentResolver: event.resolver,
              availableResolvers: prev.availableResolvers,
            ),
          );
        } else {
          add(const LoadSystemControlsEvent());
        }
      },
    );
  }

  Future<void> _onSetCustomDnsIp(
    SetCustomDnsIpEvent event,
    Emitter<SystemControlsState> emit,
  ) async {
    final customResolver = DnsResolverEntity(
      id: 'custom',
      name: 'Custom DNS',
      primaryIp: event.ip.trim(),
      secondaryIp: '',
      isCustom: true,
    );

    final prev = state;
    final result = await _setDnsResolver(
      SetDnsResolverParams(resolver: customResolver),
    );

    result.fold(
      (failure) => emit(SystemControlsError(failure.message)),
      (_) {
        final available = prev is SystemControlsLoaded
            ? [
                ...prev.availableResolvers.where((r) => r.id != 'custom'),
                customResolver,
              ]
            : [
                ...DnsResolverEntity.predefined,
                customResolver,
              ];

        emit(
          SystemControlsLoaded(
            currentResolver: customResolver,
            availableResolvers: available,
          ),
        );
      },
    );
  }
}
