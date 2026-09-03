import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/domain_filter/data/datasources/domain_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPreferences;
  late DomainLocalDataSourceImpl dataSource;

  setUp(() {
    mockPreferences = MockSharedPreferences();
    dataSource = DomainLocalDataSourceImpl(mockPreferences);
  });

  group('DomainLocalDataSource', () {
    test('returns empty list when SharedPreferences has no cached domains', () async {
      when(() => mockPreferences.getString(DomainLocalDataSourceImpl.blockedDomainsKey))
          .thenReturn(null);

      final domains = await dataSource.getDomains();

      expect(domains, isEmpty);
    });

    test('returns decoded domains from JSON storage', () async {
      final jsonList = [
        {
          'id': 'd_1',
          'domain': 'reddit.com',
          'isBlocked': true,
          'createdAt': '2026-01-01T00:00:00.000Z',
        }
      ];
      when(() => mockPreferences.getString(DomainLocalDataSourceImpl.blockedDomainsKey))
          .thenReturn(jsonEncode(jsonList));

      final domains = await dataSource.getDomains();

      expect(domains.length, 1);
      expect(domains.first.domain, 'reddit.com');
      expect(domains.first.isBlocked, isTrue);
    });

    test('addDomain sanitizes and appends new domain to storage', () async {
      when(() => mockPreferences.getString(DomainLocalDataSourceImpl.blockedDomainsKey))
          .thenReturn(jsonEncode([]));
      when(() => mockPreferences.setString(any(), any()))
          .thenAnswer((_) async => true);

      final added = await dataSource.addDomain('  Twitter.com  ');

      expect(added.domain, 'twitter.com');
      expect(added.isBlocked, isTrue);
      verify(() => mockPreferences.setString(DomainLocalDataSourceImpl.blockedDomainsKey, any()))
          .called(1);
    });

    test('toggleDomain toggles isBlocked state of existing domain', () async {
      final jsonList = [
        {
          'id': 'd_1',
          'domain': 'reddit.com',
          'isBlocked': true,
          'createdAt': '2026-01-01T00:00:00.000Z',
        }
      ];
      when(() => mockPreferences.getString(DomainLocalDataSourceImpl.blockedDomainsKey))
          .thenReturn(jsonEncode(jsonList));
      when(() => mockPreferences.setString(any(), any()))
          .thenAnswer((_) async => true);

      final updated = await dataSource.toggleDomain('d_1', false);

      expect(updated.isBlocked, isFalse);
      verify(() => mockPreferences.setString(DomainLocalDataSourceImpl.blockedDomainsKey, any()))
          .called(1);
    });

    test('removeDomain removes domain by id', () async {
      final jsonList = [
        {
          'id': 'd_1',
          'domain': 'reddit.com',
          'isBlocked': true,
          'createdAt': '2026-01-01T00:00:00.000Z',
        }
      ];
      when(() => mockPreferences.getString(DomainLocalDataSourceImpl.blockedDomainsKey))
          .thenReturn(jsonEncode(jsonList));
      when(() => mockPreferences.setString(any(), any()))
          .thenAnswer((_) async => true);

      await dataSource.removeDomain('d_1');

      verify(() => mockPreferences.setString(DomainLocalDataSourceImpl.blockedDomainsKey, '[]'))
          .called(1);
    });
  });
}
