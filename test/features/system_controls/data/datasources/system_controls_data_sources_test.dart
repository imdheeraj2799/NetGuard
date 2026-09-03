import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/system_controls/data/datasources/system_controls_local_data_source.dart';
import 'package:net_guard/features/system_controls/data/datasources/system_controls_native_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemControlsLocalDataSource Tests', () {
    test('getSelectedDnsId returns default cloudflare when unset', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = SystemControlsLocalDataSourceImpl(prefs);

      final id = await dataSource.getSelectedDnsId();
      expect(id, 'cloudflare');
    });

    test('setSelectedDnsId persists value correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = SystemControlsLocalDataSourceImpl(prefs);

      await dataSource.setSelectedDnsId('google');
      final id = await dataSource.getSelectedDnsId();
      expect(id, 'google');
    });

    test('setCustomDnsIp and getCustomDnsIp work as expected', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = SystemControlsLocalDataSourceImpl(prefs);

      await dataSource.setCustomDnsIp('9.9.9.9');
      final ip = await dataSource.getCustomDnsIp();
      expect(ip, '9.9.9.9');
    });
  });

  group('SystemControlsNativeDataSource Tests', () {
    const channel = MethodChannel('com.app.net_guard/dns_filter');
    final log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        log.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('setCustomDnsResolver invokes setCustomDnsResolver method', () async {
      final dataSource = SystemControlsNativeDataSourceImpl(
        primaryChannel: channel,
      );

      await dataSource.setCustomDnsResolver('8.8.8.8');

      expect(log.length, 1);
      expect(log.first.method, 'setCustomDnsResolver');
      expect(log.first.arguments, {'dnsServer': '8.8.8.8'});
    });
  });
}
