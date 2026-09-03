import 'package:flutter/services.dart';

abstract class SystemControlsNativeDataSource {
  Future<void> setCustomDnsResolver(String dnsServerIp);
}

class SystemControlsNativeDataSourceImpl
    implements SystemControlsNativeDataSource {
  const SystemControlsNativeDataSourceImpl({
    MethodChannel? primaryChannel,
    MethodChannel? fallbackChannel,
  })  : _primaryChannel = primaryChannel ??
            const MethodChannel('com.app.net_guard/dns_filter'),
        _fallbackChannel = fallbackChannel ??
            const MethodChannel('com.example.blocker/traffic');

  final MethodChannel _primaryChannel;
  final MethodChannel _fallbackChannel;

  @override
  Future<void> setCustomDnsResolver(String dnsServerIp) async {
    try {
      await _primaryChannel.invokeMethod('setCustomDnsResolver', {
        'dnsServer': dnsServerIp,
      });
    } on PlatformException {
      // Fallback channel compatibility
      await _fallbackChannel.invokeMethod('setCustomDnsResolver', {
        'dnsServer': dnsServerIp,
      });
    }
  }
}
