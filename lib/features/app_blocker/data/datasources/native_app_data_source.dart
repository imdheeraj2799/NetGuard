import 'package:flutter/services.dart';

abstract class NativeAppDataSource {
  Future<void> updateBlockedList(List<String> blockedPackages);
  Future<void> stopVpnService();
}

class NativeAppDataSourceImpl implements NativeAppDataSource {
  NativeAppDataSourceImpl({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.example.blocker/traffic';
  final MethodChannel _channel;

  @override
  Future<void> updateBlockedList(List<String> blockedPackages) async {
    try {
      await _channel.invokeMethod<void>('updateBlockedList', {
        'blockedPackages': blockedPackages,
      });
    } on PlatformException catch (error) {
      throw NativeDataSourceException(
        error.message ?? 'Unable to update blocked applications',
      );
    }
  }

  @override
  Future<void> stopVpnService() async {
    try {
      await _channel.invokeMethod<void>('stopVpnService');
    } on PlatformException catch (error) {
      throw NativeDataSourceException(
        error.message ?? 'Unable to stop blocking service',
      );
    }
  }
}

class NativeDataSourceException implements Exception {
  const NativeDataSourceException(this.message);
  final String message;
}
