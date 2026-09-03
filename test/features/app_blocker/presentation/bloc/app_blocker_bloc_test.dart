import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/get_installed_apps_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/toggle_block_status_usecase.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_bloc.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_event.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_state.dart';

class MockGetInstalledAppsUseCase extends Mock
    implements GetInstalledAppsUseCase {}

class MockToggleBlockStatusUseCase extends Mock
    implements ToggleBlockStatusUseCase {}

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

  setUpAll(() {
    registerFallbackValue(FakeToggleBlockStatusParams());
  });

  setUp(() {
    getInstalledApps = MockGetInstalledAppsUseCase();
    toggleBlockStatus = MockToggleBlockStatusUseCase();
  });

  AppBlockerBloc buildBloc() => AppBlockerBloc(
    getInstalledApps: getInstalledApps,
    toggleBlockStatus: toggleBlockStatus,
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
}
