import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/app_blocker_repository.dart';

class RestartVpnUseCase implements UseCase<void, NoParams> {
  const RestartVpnUseCase(this.repository);

  final AppBlockerRepository repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.restartVpn();
  }
}
