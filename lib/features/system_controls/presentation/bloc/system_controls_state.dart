import 'package:flutter/foundation.dart';
import '../../domain/entities/dns_resolver_entity.dart';

abstract class SystemControlsState {
  const SystemControlsState();
}

class SystemControlsInitial extends SystemControlsState {
  const SystemControlsInitial();
}

class SystemControlsLoading extends SystemControlsState {
  const SystemControlsLoading();
}

class SystemControlsLoaded extends SystemControlsState {
  const SystemControlsLoaded({
    required this.currentResolver,
    required this.availableResolvers,
  });

  final DnsResolverEntity currentResolver;
  final List<DnsResolverEntity> availableResolvers;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemControlsLoaded &&
          runtimeType == other.runtimeType &&
          currentResolver == other.currentResolver &&
          listEquals(availableResolvers, other.availableResolvers);

  @override
  int get hashCode =>
      currentResolver.hashCode ^ Object.hashAll(availableResolvers);
}

class SystemControlsError extends SystemControlsState {
  const SystemControlsError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemControlsError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
