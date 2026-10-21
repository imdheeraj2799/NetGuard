import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/data/datasources/native_app_data_source.dart';
import 'package:net_guard/features/app_blocker/domain/entities/vpn_status_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.example.blocker/traffic');
  late NativeAppDataSourceImpl dataSource;

  setUp(() {
    dataSource = NativeAppDataSourceImpl(channel: channel);
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('converts native VPN errors to data source exceptions', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async =>
              throw PlatformException(code: 'denied', message: 'Denied'),
        );

    expect(
      dataSource.updateBlockedList(['mail']),
      throwsA(isA<NativeDataSourceException>()),
    );
  });

  test('sends the complete blocked list to native Android code', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'updateBlockedList');
          expect(call.arguments, {
            'blockedPackages': ['mail'],
          });
          return null;
        });

    await dataSource.updateBlockedList(['mail']);
  });

  test('requests VPN shutdown when no applications remain blocked', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'stopVpnService');
          return null;
        });

    await dataSource.stopVpnService();
  });

  test('retrieves active VPN status from native code', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getVpnStatus');
          return {
            'status': 'active',
            'blockedCount': 2,
            'reason': null,
          };
        });

    final result = await dataSource.getVpnStatus();
    expect(result.status, VpnStatus.active);
    expect(result.blockedCount, 2);
    expect(result.reason, isNull);
  });

  test('converts getVpnStatus error to NativeDataSourceException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async =>
              throw PlatformException(code: 'error', message: 'Status error'),
        );

    expect(
      dataSource.getVpnStatus(),
      throwsA(isA<NativeDataSourceException>()),
    );
  });

  test('invokes restartVpn on native channel', () async {
    var restartCalled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'restartVpn') {
            restartCalled = true;
          }
          return null;
        });

    await dataSource.restartVpn();
    expect(restartCalled, isTrue);
  });

  test('converts restartVpn error to NativeDataSourceException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async =>
              throw PlatformException(code: 'error', message: 'Restart error'),
        );

    expect(
      dataSource.restartVpn(),
      throwsA(isA<NativeDataSourceException>()),
    );
  });
}
