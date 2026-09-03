import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/domain_filter/domain/entities/blocked_domain_entity.dart';
import 'package:net_guard/features/domain_filter/domain/repositories/domain_filter_repository.dart';
import 'package:net_guard/features/domain_filter/domain/usecases/add_domain_usecase.dart';
import 'package:net_guard/features/domain_filter/domain/usecases/get_blocked_domains_usecase.dart';
import 'package:net_guard/features/domain_filter/domain/usecases/remove_domain_usecase.dart';
import 'package:net_guard/features/domain_filter/domain/usecases/toggle_domain_usecase.dart';

class MockDomainFilterRepository extends Mock
    implements DomainFilterRepository {}

void main() {
  late MockDomainFilterRepository repository;
  late GetBlockedDomainsUseCase getBlockedDomainsUseCase;
  late AddDomainUseCase addDomainUseCase;
  late ToggleDomainUseCase toggleDomainUseCase;
  late RemoveDomainUseCase removeDomainUseCase;

  final testDate = DateTime(2026, 1, 1);
  final testDomain = BlockedDomainEntity(
    id: 'domain_1',
    domain: 'youtube.com',
    isBlocked: true,
    createdAt: testDate,
  );

  setUp(() {
    repository = MockDomainFilterRepository();
    getBlockedDomainsUseCase = GetBlockedDomainsUseCase(repository);
    addDomainUseCase = AddDomainUseCase(repository);
    toggleDomainUseCase = ToggleDomainUseCase(repository);
    removeDomainUseCase = RemoveDomainUseCase(repository);
  });

  group('GetBlockedDomainsUseCase', () {
    test('returns list of blocked domains from repository on success', () async {
      when(() => repository.getBlockedDomains())
          .thenAnswer((_) async => Right([testDomain]));

      final result = await getBlockedDomainsUseCase(const NoParams());

      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (domains) => expect(domains, [testDomain]),
      );
      verify(() => repository.getBlockedDomains()).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('returns failure from repository on error', () async {
      const failure = CacheFailure('Failed to load domains');
      when(() => repository.getBlockedDomains())
          .thenAnswer((_) async => const Left(failure));

      final result = await getBlockedDomainsUseCase(const NoParams());

      expect(result, const Left(failure));
      verify(() => repository.getBlockedDomains()).called(1);
      verifyNoMoreInteractions(repository);
    });
  });

  group('AddDomainUseCase', () {
    test('adds domain and returns newly created entity on success', () async {
      when(() => repository.addDomain('youtube.com'))
          .thenAnswer((_) async => Right(testDomain));

      final result = await addDomainUseCase(const AddDomainParams('youtube.com'));

      expect(result, Right(testDomain));
      verify(() => repository.addDomain('youtube.com')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('returns failure when add fails', () async {
      const failure = CacheFailure('Domain already exists');
      when(() => repository.addDomain('youtube.com'))
          .thenAnswer((_) async => const Left(failure));

      final result = await addDomainUseCase(const AddDomainParams('youtube.com'));

      expect(result, const Left(failure));
      verify(() => repository.addDomain('youtube.com')).called(1);
      verifyNoMoreInteractions(repository);
    });
  });

  group('ToggleDomainUseCase', () {
    test('toggles domain block status and returns updated entity', () async {
      final updatedDomain = testDomain.copyWith(isBlocked: false);
      when(() => repository.toggleDomain('domain_1', false))
          .thenAnswer((_) async => Right(updatedDomain));

      final result = await toggleDomainUseCase(
        const ToggleDomainParams(id: 'domain_1', isBlocked: false),
      );

      expect(result, Right(updatedDomain));
      verify(() => repository.toggleDomain('domain_1', false)).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('returns failure when toggle fails', () async {
      const failure = PlatformFailure('Native sync failed');
      when(() => repository.toggleDomain('domain_1', false))
          .thenAnswer((_) async => const Left(failure));

      final result = await toggleDomainUseCase(
        const ToggleDomainParams(id: 'domain_1', isBlocked: false),
      );

      expect(result, const Left(failure));
      verify(() => repository.toggleDomain('domain_1', false)).called(1);
      verifyNoMoreInteractions(repository);
    });
  });

  group('RemoveDomainUseCase', () {
    test('removes domain by id and returns Right(null)', () async {
      when(() => repository.removeDomain('domain_1'))
          .thenAnswer((_) async => const Right(null));

      final result = await removeDomainUseCase(const RemoveDomainParams('domain_1'));

      expect(result, const Right(null));
      verify(() => repository.removeDomain('domain_1')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('returns failure when remove fails', () async {
      const failure = CacheFailure('Domain not found');
      when(() => repository.removeDomain('domain_1'))
          .thenAnswer((_) async => const Left(failure));

      final result = await removeDomainUseCase(const RemoveDomainParams('domain_1'));

      expect(result, const Left(failure));
      verify(() => repository.removeDomain('domain_1')).called(1);
      verifyNoMoreInteractions(repository);
    });
  });
}
