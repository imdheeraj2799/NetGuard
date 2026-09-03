import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/system_controls/domain/entities/dns_resolver_entity.dart';
import 'package:net_guard/features/system_controls/domain/repositories/system_controls_repository.dart';
import 'package:net_guard/features/system_controls/domain/usecases/get_dns_settings_usecase.dart';
import 'package:net_guard/features/system_controls/domain/usecases/set_dns_resolver_usecase.dart';

class MockSystemControlsRepository extends Mock
    implements SystemControlsRepository {}

void main() {
  late MockSystemControlsRepository mockRepo;
  late GetDnsSettingsUseCase getDnsSettingsUseCase;
  late SetDnsResolverUseCase setDnsResolverUseCase;

  setUpAll(() {
    registerFallbackValue(DnsResolverEntity.cloudflare);
    registerFallbackValue(NoParams());
  });

  setUp(() {
    mockRepo = MockSystemControlsRepository();
    getDnsSettingsUseCase = GetDnsSettingsUseCase(mockRepo);
    setDnsResolverUseCase = SetDnsResolverUseCase(mockRepo);
  });

  group('System Controls Domain UseCases', () {
    test('GetDnsSettingsUseCase returns current and available resolvers', () async {
      when(() => mockRepo.getActiveDnsResolver())
          .thenAnswer((_) async => const Right(DnsResolverEntity.cloudflare));
      when(() => mockRepo.getAvailableDnsResolvers()).thenAnswer(
        (_) async => const Right(DnsResolverEntity.predefined),
      );

      final result = await getDnsSettingsUseCase(NoParams());

      expect(
        result,
        const Right(
          DnsSettingsResult(
            currentResolver: DnsResolverEntity.cloudflare,
            availableResolvers: DnsResolverEntity.predefined,
          ),
        ),
      );
      verify(() => mockRepo.getActiveDnsResolver()).called(1);
      verify(() => mockRepo.getAvailableDnsResolvers()).called(1);
    });

    test('SetDnsResolverUseCase validates IPv4 when custom is selected', () async {
      const invalidCustom = DnsResolverEntity(
        id: 'custom',
        name: 'Custom',
        primaryIp: '999.999.999.999',
        secondaryIp: '',
        isCustom: true,
      );

      final result = await setDnsResolverUseCase(
        const SetDnsResolverParams(resolver: invalidCustom),
      );

      expect(
        result,
        const Left(ValidationFailure('Invalid IPv4 DNS address.')),
      );
      verifyNever(() => mockRepo.setDnsResolver(any()));
    });

    test('SetDnsResolverUseCase calls repository when resolver valid', () async {
      when(() => mockRepo.setDnsResolver(DnsResolverEntity.google))
          .thenAnswer((_) async => const Right(null));

      final result = await setDnsResolverUseCase(
        const SetDnsResolverParams(resolver: DnsResolverEntity.google),
      );

      expect(result, const Right(null));
      verify(() => mockRepo.setDnsResolver(DnsResolverEntity.google)).called(1);
    });
  });
}
