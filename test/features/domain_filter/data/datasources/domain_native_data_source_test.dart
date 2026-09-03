import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/domain_filter/data/datasources/domain_native_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.app.net_guard/dns_filter');
  late DomainNativeDataSourceImpl dataSource;
  final List<MethodCall> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      methodCalls.add(call);
      if (call.method == 'updateDnsBlacklist') {
        return null;
      }
      throw PlatformException(code: 'UNHANDLED', message: 'Not implemented');
    });
    dataSource = DomainNativeDataSourceImpl(channel: channel);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('updateDnsBlacklist invokes MethodChannel with correct arguments', () async {
    final domains = ['youtube.com', 'reddit.com'];
    await dataSource.updateDnsBlacklist(domains);

    expect(methodCalls.length, 1);
    expect(methodCalls.first.method, 'updateDnsBlacklist');
    expect(methodCalls.first.arguments, {'domains': domains});
  });

  test('throws DomainNativeDataSourceException when platform channel fails', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      throw PlatformException(code: 'ERROR', message: 'DNS service not active');
    });

    expect(
      () => dataSource.updateDnsBlacklist(['youtube.com']),
      throwsA(isA<DomainNativeDataSourceException>()),
    );
  });
}
