import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/system_controls/data/datasources/system_controls_local_data_source.dart';
import 'package:net_guard/features/system_controls/data/datasources/system_controls_native_data_source.dart';
import 'package:net_guard/features/system_controls/data/repositories/system_controls_repository_impl.dart';
import 'package:net_guard/features/system_controls/domain/entities/dns_resolver_entity.dart';

class MockSystemControlsLocalDataSource extends Mock
    implements SystemControlsLocalDataSource {}

class MockSystemControlsNativeDataSource extends Mock
    implements SystemControlsNativeDataSource {}

void main() {
  late MockSystemControlsLocalDataSource mockLocal;
  late MockSystemControlsNativeDataSource mockNative;
  late SystemControlsRepositoryImpl repository;

  setUp(() {
    mockLocal = MockSystemControlsLocalDataSource();
    mockNative = MockSystemControlsNativeDataSource();
    repository = SystemControlsRepositoryImpl(
      localDataSource: mockLocal,
      nativeDataSource: mockNative,
    );
  });

  group('SystemControlsRepositoryImpl Tests', () {
    test('getActiveDnsResolver returns cloudflare when stored id is cloudflare', () async {
      when(() => mockLocal.getSelectedDnsId()).thenAnswer((_) async => 'cloudflare');
      when(() => mockLocal.getCustomDnsIp()).thenAnswer((_) async => null);

      final result = await repository.getActiveDnsResolver();

      expect(result, const Right(DnsResolverEntity.cloudflare));
    });

    test('getActiveDnsResolver returns custom resolver when selected id is custom', () async {
      when(() => mockLocal.getSelectedDnsId()).thenAnswer((_) async => 'custom');
      when(() => mockLocal.getCustomDnsIp()).thenAnswer((_) async => '1.1.1.2');

      final result = await repository.getActiveDnsResolver();

      expect(
        result,
        const Right(
          DnsResolverEntity(
            id: 'custom',
            name: 'Custom DNS',
            primaryIp: '1.1.1.2',
            secondaryIp: '',
            isCustom: true,
          ),
        ),
      );
    });

    test('setDnsResolver persists id and invokes native method', () async {
      when(() => mockLocal.setSelectedDnsId('google'))
          .thenAnswer((_) async {});
      when(() => mockNative.setCustomDnsResolver('8.8.8.8'))
          .thenAnswer((_) async {});

      final result = await repository.setDnsResolver(DnsResolverEntity.google);

      expect(result, const Right(null));
      verify(() => mockLocal.setSelectedDnsId('google')).called(1);
      verify(() => mockNative.setCustomDnsResolver('8.8.8.8')).called(1);
    });
  });
}
