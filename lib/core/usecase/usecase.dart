import 'package:dartz/dartz.dart';

import '../error/failure.dart';

abstract class UseCase<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}

class NoParams {
  const NoParams();
}
