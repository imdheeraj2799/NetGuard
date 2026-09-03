import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';
import 'package:net_guard/features/app_blocker/domain/repositories/app_blocker_repository.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/get_installed_apps_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/toggle_block_status_usecase.dart';

class MockAppBlockerRepository extends Mock implements AppBlockerRepository {}

void main() {
  late MockAppBlockerRepository repository;

  setUp(() => repository = MockAppBlockerRepository());

  group('GetInstalledAppsUseCase', () {
    test('returns apps from repository on success', () async {
      final apps = [
        const AppInfoEntity(
          appName: 'Maps',
          packageName: 'maps',
          isBlocked: false,
        ),
      ];
      when(() => repository.getInstalledApps())
          .thenAnswer((_) async => Right(apps));

      final result = await GetInstalledAppsUseCase(repository)(
        const NoParams(),
      );

      expect(result, Right<Failure, List<AppInfoEntity>>(apps));
      verify(() => repository.getInstalledApps()).called(1);
    });

    test('returns repository failure', () async {
      const failure = PlatformFailure('unavailable');
      when(() => repository.getInstalledApps())
          .thenAnswer((_) async => const Left(failure));

      final result = await GetInstalledAppsUseCase(repository)(
        const NoParams(),
      );

      expect(result, const Left<Failure, List<AppInfoEntity>>(failure));
    });
  });

  group('ToggleBlockStatusUseCase', () {
    const params = ToggleBlockStatusParams(
      packageName: 'maps',
      isBlocked: true,
    );

    test('delegates toggle parameters and returns success', () async {
      when(
        () =>
            repository.toggleBlockStatus(packageName: 'maps', isBlocked: true),
      ).thenAnswer((_) async => const Right(null));

      final result = await ToggleBlockStatusUseCase(repository)(params);

      expect(result, const Right<Failure, void>(null));
      verify(
        () =>
            repository.toggleBlockStatus(packageName: 'maps', isBlocked: true),
      ).called(1);
    });

    test('returns repository failure', () async {
      const failure = CacheFailure('write failed');
      when(
        () =>
            repository.toggleBlockStatus(packageName: 'maps', isBlocked: true),
      ).thenAnswer((_) async => const Left(failure));

      final result = await ToggleBlockStatusUseCase(repository)(params);

      expect(result, const Left<Failure, void>(failure));
    });
  });
}
