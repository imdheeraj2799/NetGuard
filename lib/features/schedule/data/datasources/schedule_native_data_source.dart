import 'package:flutter/services.dart';

class ScheduleNativeDataSourceException implements Exception {
  const ScheduleNativeDataSourceException(this.message);
  final String message;

  @override
  String toString() => 'ScheduleNativeDataSourceException: $message';
}

abstract class ScheduleNativeDataSource {
  Future<void> syncActiveScheduledPackages(List<String> packages);
}

class ScheduleNativeDataSourceImpl implements ScheduleNativeDataSource {
  ScheduleNativeDataSourceImpl({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.app.net_guard/traffic');

  final MethodChannel _channel;

  @override
  Future<void> syncActiveScheduledPackages(List<String> packages) async {
    try {
      await _channel.invokeMethod('updateBlockedList', {
        'blockedPackages': packages,
      });
    } on PlatformException catch (e) {
      throw ScheduleNativeDataSourceException(
        e.message ?? 'Failed to synchronize scheduled packages with native VPN',
      );
    } catch (e) {
      throw ScheduleNativeDataSourceException(
        'Unexpected native error syncing scheduled packages: $e',
      );
    }
  }
}
