import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/system_controls/domain/entities/dns_resolver_entity.dart';
import 'package:net_guard/features/system_controls/domain/usecases/get_dns_settings_usecase.dart';
import 'package:net_guard/features/system_controls/domain/usecases/set_dns_resolver_usecase.dart';
import 'package:net_guard/features/system_controls/presentation/bloc/system_controls_bloc.dart';
import 'package:net_guard/features/system_controls/presentation/bloc/system_controls_event.dart';
import 'package:net_guard/features/system_controls/presentation/bloc/system_controls_state.dart';

class MockGetDnsSettingsUseCase extends Mock implements GetDnsSettingsUseCase {}

class MockSetDnsResolverUseCase extends Mock implements SetDnsResolverUseCase {}

void main() {
  late MockGetDnsSettingsUseCase mockGetDns;
  late MockSetDnsResolverUseCase mockSetDns;
  late SystemControlsBloc bloc;

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(
      const SetDnsResolverParams(resolver: DnsResolverEntity.cloudflare),
    );
  });

  setUp(() {
    mockGetDns = MockGetDnsSettingsUseCase();
    mockSetDns = MockSetDnsResolverUseCase();
    bloc = SystemControlsBloc(
      getDnsSettings: mockGetDns,
      setDnsResolver: mockSetDns,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('SystemControlsBloc Tests', () {
    test('initial state is SystemControlsInitial', () {
      expect(bloc.state, const SystemControlsInitial());
    });

    blocTest<SystemControlsBloc, SystemControlsState>(
      'emits [Loading, Loaded] when LoadSystemControlsEvent succeeds',
      build: () {
        when(() => mockGetDns(any())).thenAnswer(
          (_) async => const Right(
            DnsSettingsResult(
              currentResolver: DnsResolverEntity.cloudflare,
              availableResolvers: DnsResolverEntity.predefined,
            ),
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadSystemControlsEvent()),
      expect: () => [
        const SystemControlsLoading(),
        const SystemControlsLoaded(
          currentResolver: DnsResolverEntity.cloudflare,
          availableResolvers: DnsResolverEntity.predefined,
        ),
      ],
    );

    blocTest<SystemControlsBloc, SystemControlsState>(
      'emits [Loaded] with updated resolver when SelectDnsResolverEvent succeeds',
      build: () {
        when(() => mockSetDns(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => const SystemControlsLoaded(
        currentResolver: DnsResolverEntity.cloudflare,
        availableResolvers: DnsResolverEntity.predefined,
      ),
      act: (b) => b.add(const SelectDnsResolverEvent(DnsResolverEntity.google)),
      expect: () => [
        const SystemControlsLoaded(
          currentResolver: DnsResolverEntity.google,
          availableResolvers: DnsResolverEntity.predefined,
        ),
      ],
    );

    blocTest<SystemControlsBloc, SystemControlsState>(
      'emits [Error] when SelectDnsResolverEvent fails',
      build: () {
        when(() => mockSetDns(any())).thenAnswer(
          (_) async => const Left(PlatformFailure('Native error')),
        );
        return bloc;
      },
      act: (b) => b.add(const SelectDnsResolverEvent(DnsResolverEntity.adguard)),
      expect: () => [
        const SystemControlsError('Native error'),
      ],
    );
  });
}
