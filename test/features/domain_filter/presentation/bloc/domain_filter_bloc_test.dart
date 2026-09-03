import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/domain_filter/domain/entities/blocked_domain_entity.dart';
import 'package:net_guard/features/domain_filter/domain/usecases/add_domain_usecase.dart';
import 'package:net_guard/features/domain_filter/domain/usecases/get_blocked_domains_usecase.dart';
import 'package:net_guard/features/domain_filter/domain/usecases/remove_domain_usecase.dart';
import 'package:net_guard/features/domain_filter/domain/usecases/toggle_domain_usecase.dart';
import 'package:net_guard/features/domain_filter/presentation/bloc/domain_filter_bloc.dart';
import 'package:net_guard/features/domain_filter/presentation/bloc/domain_filter_event.dart';
import 'package:net_guard/features/domain_filter/presentation/bloc/domain_filter_state.dart';

class MockGetBlockedDomainsUseCase extends Mock
    implements GetBlockedDomainsUseCase {}

class MockAddDomainUseCase extends Mock implements AddDomainUseCase {}

class MockToggleDomainUseCase extends Mock implements ToggleDomainUseCase {}

class MockRemoveDomainUseCase extends Mock implements RemoveDomainUseCase {}

class FakeAddDomainParams extends Fake implements AddDomainParams {}

class FakeToggleDomainParams extends Fake implements ToggleDomainParams {}

class FakeRemoveDomainParams extends Fake implements RemoveDomainParams {}

void main() {
  late MockGetBlockedDomainsUseCase getBlockedDomains;
  late MockAddDomainUseCase addDomain;
  late MockToggleDomainUseCase toggleDomain;
  late MockRemoveDomainUseCase removeDomain;

  final testDomains = [
    BlockedDomainEntity(
      id: 'd_1',
      domain: 'youtube.com',
      isBlocked: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    BlockedDomainEntity(
      id: 'd_2',
      domain: 'reddit.com',
      isBlocked: false,
      createdAt: DateTime(2026, 1, 2),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeAddDomainParams());
    registerFallbackValue(FakeToggleDomainParams());
    registerFallbackValue(FakeRemoveDomainParams());
  });

  setUp(() {
    getBlockedDomains = MockGetBlockedDomainsUseCase();
    addDomain = MockAddDomainUseCase();
    toggleDomain = MockToggleDomainUseCase();
    removeDomain = MockRemoveDomainUseCase();
  });

  DomainFilterBloc buildBloc() => DomainFilterBloc(
        getBlockedDomains: getBlockedDomains,
        addDomain: addDomain,
        toggleDomain: toggleDomain,
        removeDomain: removeDomain,
      );

  group('DomainFilterBloc', () {
    test('initial state is DomainFilterInitial', () {
      expect(buildBloc().state, isA<DomainFilterInitial>());
    });

    blocTest<DomainFilterBloc, DomainFilterState>(
      'emits [Loading, Loaded] when LoadDomainsEvent succeeds',
      build: () {
        when(() => getBlockedDomains(const NoParams()))
            .thenAnswer((_) async => Right(testDomains));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadDomainsEvent()),
      expect: () => [
        isA<DomainFilterLoading>(),
        DomainFilterLoaded(
          allDomains: testDomains,
          filteredDomains: testDomains,
        ),
      ],
    );

    blocTest<DomainFilterBloc, DomainFilterState>(
      'emits [Loading, Error] when LoadDomainsEvent fails',
      build: () {
        when(() => getBlockedDomains(const NoParams()))
            .thenAnswer((_) async => const Left(CacheFailure('Error loading')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadDomainsEvent()),
      expect: () => [
        isA<DomainFilterLoading>(),
        const DomainFilterError('Error loading'),
      ],
    );

    blocTest<DomainFilterBloc, DomainFilterState>(
      'emits updated Loaded state when AddDomainEvent succeeds',
      build: () {
        final newDomain = BlockedDomainEntity(
          id: 'd_3',
          domain: 'twitter.com',
          isBlocked: true,
          createdAt: DateTime(2026, 1, 3),
        );
        when(() => addDomain(any()))
            .thenAnswer((_) async => Right(newDomain));
        return buildBloc();
      },
      seed: () => DomainFilterLoaded(
        allDomains: testDomains,
        filteredDomains: testDomains,
      ),
      act: (bloc) => bloc.add(const AddDomainEvent('twitter.com')),
      expect: () => [
        isA<DomainFilterLoaded>().having(
          (s) => s.allDomains.length,
          'allDomains length',
          3,
        ),
      ],
    );

    blocTest<DomainFilterBloc, DomainFilterState>(
      'optimistically updates domain on ToggleDomainEvent',
      build: () {
        when(() => toggleDomain(any()))
            .thenAnswer((_) async => Right(testDomains.first.copyWith(isBlocked: false)));
        return buildBloc();
      },
      seed: () => DomainFilterLoaded(
        allDomains: testDomains,
        filteredDomains: testDomains,
      ),
      act: (bloc) => bloc.add(
        const ToggleDomainEvent(id: 'd_1', isBlocked: false),
      ),
      expect: () => [
        isA<DomainFilterLoaded>().having(
          (s) => s.allDomains.first.isBlocked,
          'first domain isBlocked',
          false,
        ),
      ],
    );

    blocTest<DomainFilterBloc, DomainFilterState>(
      'optimistically removes domain on RemoveDomainEvent',
      build: () {
        when(() => removeDomain(any()))
            .thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      seed: () => DomainFilterLoaded(
        allDomains: testDomains,
        filteredDomains: testDomains,
      ),
      act: (bloc) => bloc.add(const RemoveDomainEvent('d_1')),
      expect: () => [
        isA<DomainFilterLoaded>().having(
          (s) => s.allDomains.length,
          'allDomains length',
          1,
        ),
      ],
    );

    blocTest<DomainFilterBloc, DomainFilterState>(
      'filters domains on SearchDomainEvent',
      build: () => buildBloc(),
      seed: () => DomainFilterLoaded(
        allDomains: testDomains,
        filteredDomains: testDomains,
      ),
      act: (bloc) => bloc.add(const SearchDomainEvent('reddit')),
      expect: () => [
        isA<DomainFilterLoaded>()
            .having((s) => s.filteredDomains.length, 'filteredDomains length', 1)
            .having((s) => s.filteredDomains.first.domain, 'filtered domain', 'reddit.com'),
      ],
    );
  });
}
