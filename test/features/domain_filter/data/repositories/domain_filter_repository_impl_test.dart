import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/features/domain_filter/data/datasources/domain_local_data_source.dart';
import 'package:net_guard/features/domain_filter/data/datasources/domain_native_data_source.dart';
import 'package:net_guard/features/domain_filter/data/models/domain_filter_model.dart';
import 'package:net_guard/features/domain_filter/data/repositories/domain_filter_repository_impl.dart';

class MockDomainLocalDataSource extends Mock implements DomainLocalDataSource {}

class MockDomainNativeDataSource extends Mock
    implements DomainNativeDataSource {}

void main() {
  late MockDomainLocalDataSource localDataSource;
  late MockDomainNativeDataSource nativeDataSource;
  late DomainFilterRepositoryImpl repository;

  final testModel = DomainFilterModel(
    id: 'd_1',
    domain: 'youtube.com',
    isBlocked: true,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    localDataSource = MockDomainLocalDataSource();
    nativeDataSource = MockDomainNativeDataSource();
    repository = DomainFilterRepositoryImpl(
      localDataSource: localDataSource,
      nativeDataSource: nativeDataSource,
    );
  });

  group('DomainFilterRepositoryImpl', () {
    test('getBlockedDomains returns list of entities on success', () async {
      when(() => localDataSource.getDomains()).thenAnswer((_) async => [testModel]);

      final result = await repository.getBlockedDomains();

      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (domains) => expect(domains.first.domain, 'youtube.com'),
      );
      verify(() => localDataSource.getDomains()).called(1);
    });

    test('addDomain adds to local source and updates native blacklist', () async {
      when(() => localDataSource.addDomain('youtube.com'))
          .thenAnswer((_) async => testModel);
      when(() => localDataSource.getDomains())
          .thenAnswer((_) async => [testModel]);
      when(() => nativeDataSource.updateDnsBlacklist(['youtube.com']))
          .thenAnswer((_) async {});

      final result = await repository.addDomain('youtube.com');

      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (domain) => expect(domain.domain, 'youtube.com'),
      );
      verify(() => localDataSource.addDomain('youtube.com')).called(1);
      verify(() => nativeDataSource.updateDnsBlacklist(['youtube.com'])).called(1);
    });

    test('returns PlatformFailure when native DNS blacklist sync fails', () async {
      when(() => localDataSource.addDomain('youtube.com'))
          .thenAnswer((_) async => testModel);
      when(() => localDataSource.getDomains())
          .thenAnswer((_) async => [testModel]);
      when(() => nativeDataSource.updateDnsBlacklist(any()))
          .thenThrow(const DomainNativeDataSourceException('Native error'));

      final result = await repository.addDomain('youtube.com');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<PlatformFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
