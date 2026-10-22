import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/features/app_blocker/data/datasources/app_local_data_source.dart';
import 'package:net_guard/features/app_blocker/data/datasources/installed_apps_data_source.dart';
import 'package:net_guard/features/app_blocker/data/datasources/local_storage_data_source.dart';
import 'package:net_guard/features/app_blocker/data/datasources/native_app_data_source.dart';
import 'package:net_guard/features/app_blocker/data/models/app_info_model.dart';
import 'package:net_guard/features/app_blocker/data/repositories/app_blocker_repository_impl.dart';
import 'package:net_guard/features/app_blocker/domain/entities/vpn_status_entity.dart';

class MockNativeAppDataSource extends Mock implements NativeAppDataSource {}

class MockInstalledAppsDataSource extends Mock
    implements InstalledAppsDataSource {}

class MockLocalStorageDataSource extends Mock
    implements LocalStorageDataSource {}

class MockAppLocalDataSource extends Mock implements AppLocalDataSource {}

class FakeAppInfoModel extends Fake implements AppInfoModel {}

void main() {
  late MockNativeAppDataSource native;
  late MockInstalledAppsDataSource installedApps;
  late MockLocalStorageDataSource storage;
  late MockAppLocalDataSource localDataSource;
  late AppBlockerRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeAppInfoModel());
  });

  setUp(() {
    native = MockNativeAppDataSource();
    installedApps = MockInstalledAppsDataSource();
    storage = MockLocalStorageDataSource();
    localDataSource = MockAppLocalDataSource();

    when(() => localDataSource.getCachedApps()).thenAnswer((_) async => []);
    when(() => localDataSource.cacheApps(any())).thenAnswer((_) async {});
    when(() => localDataSource.saveApp(any())).thenAnswer((_) async {});
    when(() => localDataSource.deleteApps(any())).thenAnswer((_) async {});
    when(() => localDataSource.setFirstLaunchCompleted()).thenAnswer((_) async {});

    repository = AppBlockerRepositoryImpl(
      installedAppsDataSource: installedApps,
      nativeDataSource: native,
      localStorageDataSource: storage,
      appLocalDataSource: localDataSource,
    );
  });

  group('First Launch', () {
    test('stores whole installed application list in local storage on first launch', () async {
      when(() => localDataSource.isFirstLaunch()).thenAnswer((_) async => true);
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
      when(() => localDataSource.getCachedApps()).thenAnswer(
        (_) async => [
          const AppInfoModel(
            appName: 'Mail',
            packageName: 'mail',
            isBlocked: true,
          ),
          const AppInfoModel(
            appName: 'Maps',
            packageName: 'maps',
            isBlocked: false,
          ),
        ],
      );

      final result = await repository.getInstalledApps();

      expect(result, isA<Right<Failure, List<dynamic>>>());
      result.fold(
        (_) => fail('Expected apps'),
        (apps) => expect(apps.map((app) => app.isBlocked), [true, false]),
      );
      verify(() => localDataSource.cacheApps(any())).called(1);
      verify(() => localDataSource.setFirstLaunchCompleted()).called(1);
    });
  });

  group('Subsequent Launch & Conflict Resolution', () {
    test('detects uninstalled applications, removes them from cache and cleans up firewall', () async {
      when(() => localDataSource.isFirstLaunch()).thenAnswer((_) async => false);
      // Cached apps had 'mail' (blocked) and 'game' (unblocked)
      when(() => localDataSource.getCachedApps()).thenAnswer(
        (_) async => [
          const AppInfoModel(
            appName: 'Mail',
            packageName: 'mail',
            isBlocked: true,
          ),
          const AppInfoModel(
            appName: 'Game',
            packageName: 'game',
            isBlocked: false,
          ),
        ],
      );
      // Device now ONLY has 'game' (Mail was uninstalled by user)
      when(() => installedApps.getInstalledApps()).thenAnswer(
        (_) async => [
          const AppInfoModel(
            appName: 'Game',
            packageName: 'game',
            isBlocked: false,
          ),
        ],
      );
      when(() => storage.getBlockedPackages()).thenAnswer((_) async => ['mail']);
      when(() => storage.setBlockedPackages(any())).thenAnswer((_) async {});
      when(() => native.updateBlockedList(any())).thenAnswer((_) async {});

      final result = await repository.getInstalledApps();

      expect(result, isA<Right<Failure, List<dynamic>>>());
      // Verify uninstalled app was removed from Hive cache
      verify(() => localDataSource.deleteApps(['mail'])).called(1);
      // Verify blocked list updated and VPN updated since no blocked apps remain
      verify(() => storage.setBlockedPackages([])).called(1);
      verify(() => native.updateBlockedList([])).called(1);
    });

    test('detects newly installed applications and adds them to local storage', () async {
      when(() => localDataSource.isFirstLaunch()).thenAnswer((_) async => false);
      when(() => localDataSource.getCachedApps()).thenAnswer(
        (_) async => [
          const AppInfoModel(
            appName: 'Mail',
            packageName: 'mail',
            isBlocked: false,
          ),
        ],
      );
      // Device has Mail and newly installed Browser
      when(() => installedApps.getInstalledApps()).thenAnswer(
        (_) async => [
          const AppInfoModel(
            appName: 'Mail',
            packageName: 'mail',
            isBlocked: false,
          ),
          const AppInfoModel(
            appName: 'Browser',
            packageName: 'browser',
            isBlocked: false,
          ),
        ],
      );
      when(() => storage.getBlockedPackages()).thenAnswer((_) async => []);

      final result = await repository.getInstalledApps();

      expect(result, isA<Right<Failure, List<dynamic>>>());
      final captured = verify(() => localDataSource.cacheApps(captureAny())).captured;
      final cachedNew = captured.single as List<AppInfoModel>;
      expect(cachedNew.map((a) => a.packageName), ['browser']);
    });
  });

  test('returns platform failure when installed applications cannot be read', () async {
    when(() => localDataSource.isFirstLaunch()).thenAnswer((_) async => true);
    when(() => installedApps.getInstalledApps())
        .thenThrow(const InstalledAppsException('permission denied'));
    when(() => storage.getBlockedPackages()).thenAnswer((_) async => []);

    final result = await repository.getInstalledApps();

    expect(
      result.fold((failure) => failure, (_) => null),
      isA<PlatformFailure>(),
    );
  });

  test('returns cache failure when blocked cache cannot be read', () async {
    when(() => localDataSource.isFirstLaunch()).thenAnswer((_) async => true);
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

  test('updates blocked list via native updateBlockedList when the last blocked app is unblocked', () async {
    when(() => storage.getBlockedPackages()).thenAnswer((_) async => ['mail']);
    when(() => native.updateBlockedList(any())).thenAnswer((_) async {});
    when(() => storage.setBlockedPackages(any())).thenAnswer((_) async {});

    final result = await repository.toggleBlockStatus(
      packageName: 'mail',
      isBlocked: false,
    );

    expect(result, const Right<Failure, void>(null));
    verify(() => native.updateBlockedList([])).called(1);
    verifyNever(() => native.stopVpnService());
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

  group('VPN Status & Recovery', () {
    test('returns VPN status from native data source', () async {
      const expectedInfo = VpnStatusInfo(
        status: VpnStatus.active,
        blockedCount: 2,
      );
      when(() => native.getVpnStatus()).thenAnswer((_) async => expectedInfo);

      final result = await repository.getVpnStatus();

      expect(result, const Right<Failure, VpnStatusInfo>(expectedInfo));
    });

    test('maps native exception to PlatformFailure on getVpnStatus', () async {
      when(() => native.getVpnStatus())
          .thenThrow(const NativeDataSourceException('Status error'));

      final result = await repository.getVpnStatus();

      expect(
        result.fold((failure) => failure, (_) => null),
        isA<PlatformFailure>(),
      );
    });

    test('restarts VPN service through native data source', () async {
      when(() => native.restartVpn()).thenAnswer((_) async {});

      final result = await repository.restartVpn();

      expect(result, const Right<Failure, void>(null));
      verify(() => native.restartVpn()).called(1);
    });

    test('maps native exception to PlatformFailure on restartVpn', () async {
      when(() => native.restartVpn())
          .thenThrow(const NativeDataSourceException('Restart failed'));

      final result = await repository.restartVpn();

      expect(
        result.fold((failure) => failure, (_) => null),
        isA<PlatformFailure>(),
      );
    });

    test('forwards vpnStatusStream from native data source', () {
      final stream = Stream.value(
        const VpnStatusInfo(status: VpnStatus.active),
      );
      when(() => native.vpnStatusStream).thenAnswer((_) => stream);

      expect(repository.vpnStatusStream, stream);
    });
  });
}
