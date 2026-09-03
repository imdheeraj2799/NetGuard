// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/blocked_domain_entity.dart';
import '../../domain/usecases/add_domain_usecase.dart';
import '../../domain/usecases/get_blocked_domains_usecase.dart';
import '../../domain/usecases/remove_domain_usecase.dart';
import '../../domain/usecases/toggle_domain_usecase.dart';
import 'domain_filter_event.dart';
import 'domain_filter_state.dart';

class DomainFilterBloc extends Bloc<DomainFilterEvent, DomainFilterState> {
  DomainFilterBloc({
    required GetBlockedDomainsUseCase getBlockedDomains,
    required AddDomainUseCase addDomain,
    required ToggleDomainUseCase toggleDomain,
    required RemoveDomainUseCase removeDomain,
  })  : _getBlockedDomains = getBlockedDomains,
        _addDomain = addDomain,
        _toggleDomain = toggleDomain,
        _removeDomain = removeDomain,
        super(const DomainFilterInitial()) {
    on<LoadDomainsEvent>(_onLoadDomains);
    on<AddDomainEvent>(_onAddDomain);
    on<ToggleDomainEvent>(_onToggleDomain);
    on<RemoveDomainEvent>(_onRemoveDomain);
    on<SearchDomainEvent>(_onSearchDomain);
  }

  final GetBlockedDomainsUseCase _getBlockedDomains;
  final AddDomainUseCase _addDomain;
  final ToggleDomainUseCase _toggleDomain;
  final RemoveDomainUseCase _removeDomain;

  Future<void> _onLoadDomains(
    LoadDomainsEvent event,
    Emitter<DomainFilterState> emit,
  ) async {
    emit(const DomainFilterLoading());
    final result = await _getBlockedDomains(const NoParams());
    result.fold(
      (failure) => emit(DomainFilterError(failure.message)),
      (domains) => emit(_loadedState(allDomains: domains)),
    );
  }

  Future<void> _onAddDomain(
    AddDomainEvent event,
    Emitter<DomainFilterState> emit,
  ) async {
    final currentState = state;
    final query = currentState is DomainFilterLoaded ? currentState.searchQuery : '';

    final result = await _addDomain(AddDomainParams(event.domain));
    result.fold(
      (failure) => emit(DomainFilterError(failure.message)),
      (newDomain) {
        if (currentState is DomainFilterLoaded) {
          final updated = [...currentState.allDomains, newDomain];
          emit(_loadedState(allDomains: updated, query: query));
        } else {
          emit(_loadedState(allDomains: [newDomain]));
        }
      },
    );
  }

  Future<void> _onToggleDomain(
    ToggleDomainEvent event,
    Emitter<DomainFilterState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DomainFilterLoaded) return;

    final optimisticallyUpdated = currentState.allDomains
        .map((d) => d.id == event.id ? d.copyWith(isBlocked: event.isBlocked) : d)
        .toList();
    emit(_loadedState(
      allDomains: optimisticallyUpdated,
      query: currentState.searchQuery,
    ));

    final result = await _toggleDomain(
      ToggleDomainParams(id: event.id, isBlocked: event.isBlocked),
    );
    result.fold(
      (failure) => emit(DomainFilterError(failure.message)),
      (_) {},
    );
  }

  Future<void> _onRemoveDomain(
    RemoveDomainEvent event,
    Emitter<DomainFilterState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DomainFilterLoaded) return;

    final optimisticallyUpdated =
        currentState.allDomains.where((d) => d.id != event.id).toList();
    emit(_loadedState(
      allDomains: optimisticallyUpdated,
      query: currentState.searchQuery,
    ));

    final result = await _removeDomain(RemoveDomainParams(event.id));
    result.fold(
      (failure) => emit(DomainFilterError(failure.message)),
      (_) {},
    );
  }

  void _onSearchDomain(
    SearchDomainEvent event,
    Emitter<DomainFilterState> emit,
  ) {
    final currentState = state;
    if (currentState is! DomainFilterLoaded) return;
    emit(_loadedState(
      allDomains: currentState.allDomains,
      query: event.query,
    ));
  }

  DomainFilterLoaded _loadedState({
    required List<BlockedDomainEntity> allDomains,
    String query = '',
  }) {
    final sanitizedQuery = query.trim().toLowerCase();
    final filtered = allDomains.where((domain) {
      if (sanitizedQuery.isEmpty) return true;
      return domain.domain.toLowerCase().contains(sanitizedQuery);
    }).toList();

    return DomainFilterLoaded(
      allDomains: List.unmodifiable(allDomains),
      filteredDomains: List.unmodifiable(filtered),
      searchQuery: query,
    );
  }
}
