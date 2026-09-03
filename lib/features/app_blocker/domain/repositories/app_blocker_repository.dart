import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_info_entity.dart';

abstract class AppBlockerRepository {
  Future<Either<Failure, List<AppInfoEntity>>> getInstalledApps();
  Future<Either<Failure, void>> toggleBlockStatus({
    required String packageName,
    required bool isBlocked,
  });
  Future<Either<Failure, List<String>>> getBlockedPackages();
}
