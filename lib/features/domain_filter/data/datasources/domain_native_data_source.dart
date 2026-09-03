import 'package:flutter/services.dart';

abstract class DomainNativeDataSource {
  Future<void> updateDnsBlacklist(List<String> domains);
}

class DomainNativeDataSourceImpl implements DomainNativeDataSource {
  DomainNativeDataSourceImpl({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.app.net_guard/dns_filter';
  final MethodChannel _channel;

  @override
  Future<void> updateDnsBlacklist(List<String> domains) async {
    try {
      await _channel.invokeMethod<void>('updateDnsBlacklist', {
        'domains': domains,
      });
    } on PlatformException catch (error) {
      throw DomainNativeDataSourceException(
        error.message ?? 'Unable to update DNS blacklist',
      );
    }
  }
}

class DomainNativeDataSourceException implements Exception {
  const DomainNativeDataSourceException(this.message);
  final String message;

  @override
  String toString() => message;
}
