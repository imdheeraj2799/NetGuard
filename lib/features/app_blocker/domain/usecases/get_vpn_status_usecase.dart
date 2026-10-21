import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/vpn_status_entity.dart';
import '../repositories/app_blocker_repository.dart';

class GetVpnStatusUseCase implements UseCase<VpnStatusInfo, NoParams> {
  const GetVpnStatusUseCase(this.repository);

  final AppBlockerRepository repository;

  @override
  Future<Either<Failure, VpnStatusInfo>> call(NoParams params) {
    return repository.getVpnStatus();
  }
}
