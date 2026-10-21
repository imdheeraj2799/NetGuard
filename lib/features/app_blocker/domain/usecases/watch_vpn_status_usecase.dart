import '../entities/vpn_status_entity.dart';
import '../repositories/app_blocker_repository.dart';

class WatchVpnStatusUseCase {
  const WatchVpnStatusUseCase(this.repository);

  final AppBlockerRepository repository;

  Stream<VpnStatusInfo> call() {
    return repository.vpnStatusStream;
  }
}
