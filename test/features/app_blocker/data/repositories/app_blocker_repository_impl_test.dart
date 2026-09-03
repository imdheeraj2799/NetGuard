import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/features/app_blocker/data/datasources/local_storage_data_source.dart';
import 'package:net_guard/features/app_blocker/data/datasources/installed_apps_data_source.dart';
import 'package:net_guard/features/app_blocker/data/datasources/native_app_data_source.dart';
import 'package:net_guard/features/app_blocker/data/models/app_info_model.dart';
import 'package:net_guard/features/app_blocker/data/repositories/app_blocker_repository_impl.dart';

class MockNativeAppDataSource extends Mock implements NativeAppDataSource {}

class MockInstalledAppsDataSource extends Mock
    implements InstalledAppsDataSource {}

class MockLocalStorageDataSource extends Mock
    implements LocalStorageDataSource {}

void main() {
  late MockNativeAppDataSource native;
  late MockInstalledAppsDataSource installedApps;
  late MockLocalStorageDataSource storage;
  late AppBlockerRepositoryImpl repository;

  setUp(() {
    native = MockNativeAppDataSource();
    installedApps = MockInstalledAppsDataSource();
    storage = MockLocalStorageDataSource();
    repository = AppBlockerRepositoryImpl(
      installedAppsDataSource: installedApps,
      nativeDataSource: native,
      localStorageDataSource: storage,
    );
  });

  test('overlays local blocked status on installed applications', () async {
    when(() => installedApps.getInstalledApps()).thenAnswer(
      (_) async => [
        const AppInfoModel(
          appName: 'Mail',
          packageName: 'mail',
          isBlocked: false,
        ),
        const AppInfoModel(
          appName: 'Maps',
          packageName: 'maps',
          isBlocked: false,
        ),
      ],
    );
    when(() => storage.getBlockedPackages()).thenAnswer((_) async => ['mail']);

    final result = await repository.getInstalledApps();

    expect(result, isA<Right<Failure, List<dynamic>>>());
    result.fold(
      (_) => fail('Expected apps'),
      (apps) => expect(apps.map((app) => app.isBlocked), [true, false]),
    );
  });

  test(
    'returns platform failure when installed applications cannot be read',
    () async {
      when(() => installedApps.getInstalledApps())
          .thenThrow(const InstalledAppsException('permission denied'));
      when(() => storage.getBlockedPackages()).thenAnswer((_) async => []);

      final result = await repository.getInstalledApps();

      expect(
        result.fold((failure) => failure, (_) => null),
        isA<PlatformFailure>(),
      );
    },
  );

  test('returns cache failure when blocked cache cannot be read', () async {
    when(() => installedApps.getInstalledApps()).thenAnswer((_) async => []);
    when(() => storage.getBlockedPackages())
        .thenThrow(const LocalStorageException('read failed'));

    final result = await repository.getInstalledApps();

    expect(result.fold((failure) => failure, (_) => null), isA<CacheFailure>());
  });

  test('updates VPN state with the complete list and persists a newly blocked package', () async {
    when(() => native.updateBlockedList(any())).thenAnswer((_) async {});
    when(() => storage.getBlockedPackages()).thenAnswer((_) async => ['maps']);
    when(() => storage.setBlockedPackages(any())).thenAnswer((_) async {});

    final result = await repository.toggleBlockStatus(
      packageName: 'mail',
      isBlocked: true,
    );

    expect(result, const Right<Failure, void>(null));
    final nativeInvocation = verify(
      () => native.updateBlockedList(captureAny()),
    )..called(1);
    expect(nativeInvocation.captured.single, unorderedEquals(['maps', 'mail']));
    final invocation = verify(() => storage.setBlockedPackages(captureAny()))
      ..called(1);
    expect(invocation.captured.single, unorderedEquals(['maps', 'mail']));
  });

  test('does not write cache if native VPN update fails', () async {
    when(() => storage.getBlockedPackages()).thenAnswer((_) async => []);
    when(() => native.updateBlockedList(any()))
        .thenThrow(const NativeDataSourceException('vpn failed'));

    final result = await repository.toggleBlockStatus(
      packageName: 'mail',
      isBlocked: true,
    );

    expect(
      result.fold((failure) => failure, (_) => null),
      isA<PlatformFailure>(),
    );
    verifyNever(() => storage.setBlockedPackages(any()));
  });

  test('stops VPN when the last blocked app is unblocked', () async {
    when(() => storage.getBlockedPackages()).thenAnswer((_) async => ['mail']);
    when(() => native.stopVpnService()).thenAnswer((_) async {});
    when(() => storage.setBlockedPackages(any())).thenAnswer((_) async {});

    final result = await repository.toggleBlockStatus(
      packageName: 'mail',
      isBlocked: false,
    );

    expect(result, const Right<Failure, void>(null));
    verify(() => native.stopVpnService()).called(1);
    verifyNever(() => native.updateBlockedList(any()));
    verify(() => storage.setBlockedPackages([])).called(1);
  });

  test('returns cached packages and maps storage failure', () async {
    when(() => storage.getBlockedPackages()).thenAnswer((_) async => ['mail']);
    final success = await repository.getBlockedPackages();
    expect(success.fold((_) => null, (packages) => packages), ['mail']);

    when(() => storage.getBlockedPackages())
        .thenThrow(const LocalStorageException('read failed'));
    final failure = await repository.getBlockedPackages();
    expect(failure.fold((value) => value, (_) => null), isA<CacheFailure>());
  });
}
