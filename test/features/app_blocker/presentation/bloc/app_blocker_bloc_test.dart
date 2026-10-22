import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/get_installed_apps_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/toggle_block_status_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/get_vpn_status_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/restart_vpn_usecase.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_bloc.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_event.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_state.dart';

class MockGetInstalledAppsUseCase extends Mock
    implements GetInstalledAppsUseCase {}

class MockToggleBlockStatusUseCase extends Mock
    implements ToggleBlockStatusUseCase {}

class MockGetVpnStatusUseCase extends Mock implements GetVpnStatusUseCase {}

class MockRestartVpnUseCase extends Mock implements RestartVpnUseCase {}

class FakeToggleBlockStatusParams extends Fake
    implements ToggleBlockStatusParams {}

void main() {
  const apps = [
    AppInfoEntity(
      appName: 'Mail',
      packageName: 'com.example.mail',
      isBlocked: false,
    ),
    AppInfoEntity(
      appName: 'Maps',
      packageName: 'com.example.maps',
      isBlocked: true,
    ),
  ];
  late MockGetInstalledAppsUseCase getInstalledApps;
  late MockToggleBlockStatusUseCase toggleBlockStatus;
  late MockGetVpnStatusUseCase getVpnStatus;
  late MockRestartVpnUseCase restartVpn;

  setUpAll(() {
    registerFallbackValue(FakeToggleBlockStatusParams());
  });

  setUp(() {
    getInstalledApps = MockGetInstalledAppsUseCase();
    toggleBlockStatus = MockToggleBlockStatusUseCase();
    getVpnStatus = MockGetVpnStatusUseCase();
    restartVpn = MockRestartVpnUseCase();
  });

  AppBlockerBloc buildBloc({
    GetVpnStatusUseCase? customGetVpnStatus,
    RestartVpnUseCase? customRestartVpn,
  }) => AppBlockerBloc(
    getInstalledApps: getInstalledApps,
    toggleBlockStatus: toggleBlockStatus,
    getVpnStatus: customGetVpnStatus,
    restartVpn: customRestartVpn,
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'emits loading then mapped installed apps when loading succeeds',
    build: () {
      when(() => getInstalledApps(const NoParams()))
          .thenAnswer((_) async => const Right(apps));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadInstalledAppsEvent()),
    expect: () => [
      isA<AppBlockerLoading>(),
      isA<AppBlockerLoaded>()
          .having((state) => state.originalApps, 'original apps', apps)
          .having((state) => state.filteredApps, 'filtered apps', apps)
          .having((state) => state.searchQuery, 'search query', ''),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'emits an error state when loading fails',
    build: () {
      when(() => getInstalledApps(const NoParams())).thenAnswer(
        (_) async => const Left(PlatformFailure('Permission denied')),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadInstalledAppsEvent()),
    expect: () => [
      isA<AppBlockerLoading>(),
      isA<AppBlockerError>().having(
        (state) => state.message,
        'message',
        'Permission denied',
      ),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'emits a searched application list after SearchAppEvent',
    build: () => buildBloc(),
    seed: () => const AppBlockerLoaded(originalApps: apps, filteredApps: apps),
    act: (bloc) => bloc.add(const SearchAppEvent('maps')),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((state) => state.searchQuery, 'query', 'maps')
          .having(
            (state) => state.filteredApps.map((app) => app.packageName),
            'results',
            ['com.example.maps'],
          ),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'filters blocked applications',
    build: () => buildBloc(),
    seed: () => const AppBlockerLoaded(originalApps: apps, filteredApps: apps),
    act: (bloc) => bloc.add(const FilterBlockedEvent(AppBlockerFilter.blocked)),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((state) => state.filter, 'filter', AppBlockerFilter.blocked)
          .having((state) => state.filteredApps, 'results', [apps[1]]),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'optimistically updates an app before successful persistence',
    build: () {
      when(() => toggleBlockStatus(any()))
          .thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    seed: () => const AppBlockerLoaded(originalApps: apps, filteredApps: apps),
    act: (bloc) => bloc.add(
      const ToggleAppBlockEvent(
        packageName: 'com.example.mail',
        isBlocked: true,
      ),
    ),
    expect: () => [
      isA<AppBlockerLoaded>().having(
        (state) => state.originalApps.first.isBlocked,
        'optimistically updated status',
        true,
      ),
    ],
    verify: (_) {
      final invocation = verify(() => toggleBlockStatus(captureAny()))
        ..called(1);
      final parameters = invocation.captured.single as ToggleBlockStatusParams;
      expect(parameters.packageName, 'com.example.mail');
      expect(parameters.isBlocked, isTrue);
    },
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'emits optimistic update followed by error when toggling fails',
    build: () {
      when(() => toggleBlockStatus(any()))
          .thenAnswer((_) async => const Left(CacheFailure('Could not save')));
      return buildBloc();
    },
    seed: () => const AppBlockerLoaded(originalApps: apps, filteredApps: apps),
    act: (bloc) => bloc.add(
      const ToggleAppBlockEvent(
        packageName: 'com.example.mail',
        isBlocked: true,
      ),
    ),
    expect: () => [
      isA<AppBlockerLoaded>(),
      isA<AppBlockerError>().having(
        (state) => state.message,
        'message',
        'Could not save',
      ),
    ],
  );

  final twentyApps = List.generate(
    20,
    (index) => AppInfoEntity(
      appName: 'App $index',
      packageName: 'com.app.$index',
      isBlocked: false,
    ),
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'loads 15 items on page 1 when 20 apps are available',
    build: () {
      when(() => getInstalledApps(const NoParams()))
          .thenAnswer((_) async => Right(twentyApps));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadInstalledAppsEvent()),
    expect: () => [
      isA<AppBlockerLoading>(),
      isA<AppBlockerLoaded>()
          .having((s) => s.originalApps.length, 'originalApps length', 20)
          .having((s) => s.displayedApps.length, 'displayedApps length', 15)
          .having((s) => s.page, 'page', 1)
          .having((s) => s.hasReachedMax, 'hasReachedMax', isFalse),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'LoadMoreAppsEvent loads the remaining items and marks hasReachedMax as true',
    build: () => buildBloc(),
    seed: () => AppBlockerLoaded(
      originalApps: twentyApps,
      filteredApps: twentyApps,
      page: 1,
      pageSize: 15,
    ),
    act: (bloc) => bloc.add(const LoadMoreAppsEvent()),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((s) => s.displayedApps.length, 'displayedApps length', 20)
          .having((s) => s.page, 'page', 2)
          .having((s) => s.hasReachedMax, 'hasReachedMax', isTrue),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'VpnStatusUpdatedEvent updates vpnStatus and reason in AppBlockerLoaded',
    build: () => buildBloc(),
    seed: () => const AppBlockerLoaded(originalApps: apps, filteredApps: apps),
    act: (bloc) => bloc.add(
      const VpnStatusUpdatedEvent(
        status: VpnStatus.inactive,
        reason: 'VPN permission revoked',
      ),
    ),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.inactive)
          .having((s) => s.vpnStatusReason, 'vpnStatusReason', 'VPN permission revoked')
          .having((s) => s.isFirewallActive, 'isFirewallActive', isFalse),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'RestartVpnEvent emits restarting status and triggers restart usecase',
    build: () {
      when(() => restartVpn(const NoParams()))
          .thenAnswer((_) async => const Right(null));
      return buildBloc(customRestartVpn: restartVpn);
    },
    seed: () => const AppBlockerLoaded(
      originalApps: apps,
      filteredApps: apps,
      vpnStatus: VpnStatus.inactive,
      vpnStatusReason: 'Permission revoked',
    ),
    act: (bloc) => bloc.add(const RestartVpnEvent()),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.restarting)
          .having((s) => s.vpnStatusReason, 'vpnStatusReason', 'Restarting firewall...'),
    ],
    verify: (_) {
      verify(() => restartVpn(const NoParams())).called(1);
    },
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'RestartVpnEvent failure updates state to inactive with error message',
    build: () {
      when(() => restartVpn(const NoParams()))
          .thenAnswer((_) async => const Left(PlatformFailure('Permission denied')));
      return buildBloc(customRestartVpn: restartVpn);
    },
    seed: () => const AppBlockerLoaded(
      originalApps: apps,
      filteredApps: apps,
      vpnStatus: VpnStatus.inactive,
    ),
    act: (bloc) => bloc.add(const RestartVpnEvent()),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.restarting),
      isA<AppBlockerLoaded>()
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.inactive)
          .having((s) => s.vpnStatusReason, 'vpnStatusReason', 'Permission denied')
          .having((s) => s.actionErrorMessage, 'actionErrorMessage', 'Failed to restart VPN: Permission denied'),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'CheckVpnStatusEvent queries getVpnStatus and updates loaded state',
    build: () {
      when(() => getVpnStatus(const NoParams())).thenAnswer(
        (_) async => const Right(
          VpnStatusInfo(status: VpnStatus.restarting, reason: 'Recovering...'),
        ),
      );
      return buildBloc(customGetVpnStatus: getVpnStatus);
    },
    seed: () => const AppBlockerLoaded(originalApps: apps, filteredApps: apps),
    act: (bloc) => bloc.add(const CheckVpnStatusEvent()),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.restarting)
          .having((s) => s.vpnStatusReason, 'vpnStatusReason', 'Recovering...'),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'ToggleAppBlockEvent sets vpnStatus to inactive when unblocking the last blocked app',
    build: () {
      when(() => toggleBlockStatus(any()))
          .thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    seed: () => const AppBlockerLoaded(
      originalApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
        AppInfoEntity(appName: 'Maps', packageName: 'com.example.maps', isBlocked: true),
      ],
      filteredApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
        AppInfoEntity(appName: 'Maps', packageName: 'com.example.maps', isBlocked: true),
      ],
      vpnStatus: VpnStatus.active,
    ),
    act: (bloc) => bloc.add(
      const ToggleAppBlockEvent(
        packageName: 'com.example.maps',
        isBlocked: false,
      ),
    ),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((s) => s.blockedAppsCount, 'blockedAppsCount', 0)
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.inactive),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'ToggleAppBlockEvent sets vpnStatus to active when blocking the first app from inactive',
    build: () {
      when(() => toggleBlockStatus(any()))
          .thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    seed: () => const AppBlockerLoaded(
      originalApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
      ],
      filteredApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
      ],
      vpnStatus: VpnStatus.inactive,
    ),
    act: (bloc) => bloc.add(
      const ToggleAppBlockEvent(
        packageName: 'com.example.mail',
        isBlocked: true,
      ),
    ),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((s) => s.blockedAppsCount, 'blockedAppsCount', 1)
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.active),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'LoadInstalledAppsEvent initializes vpnStatus as inactive when no apps are blocked',
    build: () {
      when(() => getInstalledApps(const NoParams())).thenAnswer(
        (_) async => const Right([
          AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
        ]),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadInstalledAppsEvent()),
    expect: () => [
      isA<AppBlockerLoading>(),
      isA<AppBlockerLoaded>()
          .having((s) => s.blockedAppsCount, 'blockedAppsCount', 0)
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.inactive),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'VpnStatusUpdatedEvent forces inactive status when blockedAppsCount is 0',
    build: buildBloc,
    seed: () => const AppBlockerLoaded(
      originalApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
      ],
      filteredApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
      ],
      vpnStatus: VpnStatus.inactive,
    ),
    act: (bloc) => bloc.add(
      const VpnStatusUpdatedEvent(
        status: VpnStatus.active,
        blockedCount: 0,
      ),
    ),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((s) => s.blockedAppsCount, 'blockedAppsCount', 0)
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.inactive),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'CheckVpnStatusEvent forces inactive status when blockedAppsCount is 0 and blockedCount is 0',
    build: () {
      when(() => getVpnStatus(const NoParams())).thenAnswer(
        (_) async => const Right(VpnStatusInfo(status: VpnStatus.active, blockedCount: 0)),
      );
      return buildBloc(customGetVpnStatus: getVpnStatus);
    },
    seed: () => const AppBlockerLoaded(
      originalApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
      ],
      filteredApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
      ],
      vpnStatus: VpnStatus.active,
    ),
    act: (bloc) => bloc.add(const CheckVpnStatusEvent()),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((s) => s.blockedAppsCount, 'blockedAppsCount', 0)
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.inactive),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'CheckVpnStatusEvent preserves active status and updates activeBlockedCount when native blockedCount > 0',
    build: () {
      when(() => getVpnStatus(const NoParams())).thenAnswer(
        (_) async => const Right(
          VpnStatusInfo(status: VpnStatus.active, blockedCount: 2),
        ),
      );
      return buildBloc(customGetVpnStatus: getVpnStatus);
    },
    seed: () => const AppBlockerLoaded(
      originalApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
      ],
      filteredApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
      ],
      vpnStatus: VpnStatus.inactive,
    ),
    act: (bloc) => bloc.add(const CheckVpnStatusEvent()),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((s) => s.blockedAppsCount, 'blockedAppsCount', 0)
          .having((s) => s.activeBlockedCount, 'activeBlockedCount', 2)
          .having((s) => s.effectiveBlockedCount, 'effectiveBlockedCount', 2)
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.active),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'VpnStatusUpdatedEvent preserves active status and updates activeBlockedCount when blockedCount > 0',
    build: buildBloc,
    seed: () => const AppBlockerLoaded(
      originalApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
      ],
      filteredApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
      ],
      vpnStatus: VpnStatus.inactive,
    ),
    act: (bloc) => bloc.add(
      const VpnStatusUpdatedEvent(
        status: VpnStatus.active,
        blockedCount: 3,
      ),
    ),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having((s) => s.blockedAppsCount, 'blockedAppsCount', 0)
          .having((s) => s.activeBlockedCount, 'activeBlockedCount', 3)
          .having((s) => s.effectiveBlockedCount, 'effectiveBlockedCount', 3)
          .having((s) => s.vpnStatus, 'vpnStatus', VpnStatus.active),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'SyncScheduleRestrictionsEvent updates schedule restrictions on loaded apps',
    build: buildBloc,
    seed: () => const AppBlockerLoaded(
      originalApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
        AppInfoEntity(appName: 'Browser', packageName: 'com.example.browser', isBlocked: false),
      ],
      filteredApps: [
        AppInfoEntity(appName: 'Mail', packageName: 'com.example.mail', isBlocked: false),
        AppInfoEntity(appName: 'Browser', packageName: 'com.example.browser', isBlocked: false),
      ],
    ),
    act: (bloc) => bloc.add(
      const SyncScheduleRestrictionsEvent({
        'com.example.mail': 'Work Schedule',
      }),
    ),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having(
            (s) => s.originalApps.firstWhere((a) => a.packageName == 'com.example.mail').isSchedulePart,
            'isSchedulePart',
            isTrue,
          )
          .having(
            (s) => s.originalApps.firstWhere((a) => a.packageName == 'com.example.mail').whichSchedule,
            'whichSchedule',
            'Work Schedule',
          )
          .having(
            (s) => s.originalApps.firstWhere((a) => a.packageName == 'com.example.browser').isSchedulePart,
            'isSchedulePart for browser',
            isFalse,
          ),
    ],
  );

  blocTest<AppBlockerBloc, AppBlockerState>(
    'SyncScheduleRestrictionsEvent clears schedule restrictions when schedule is removed',
    build: buildBloc,
    seed: () => const AppBlockerLoaded(
      originalApps: [
        AppInfoEntity(
          appName: 'Mail',
          packageName: 'com.example.mail',
          isBlocked: false,
          isSchedulePart: true,
          whichSchedule: 'Work Schedule',
        ),
      ],
      filteredApps: [
        AppInfoEntity(
          appName: 'Mail',
          packageName: 'com.example.mail',
          isBlocked: false,
          isSchedulePart: true,
          whichSchedule: 'Work Schedule',
        ),
      ],
    ),
    act: (bloc) => bloc.add(
      const SyncScheduleRestrictionsEvent({}),
    ),
    expect: () => [
      isA<AppBlockerLoaded>()
          .having(
            (s) => s.originalApps.first.isSchedulePart,
            'isSchedulePart',
            isFalse,
          )
          .having(
            (s) => s.originalApps.first.whichSchedule,
            'whichSchedule',
            isNull,
          ),
    ],
  );
}
