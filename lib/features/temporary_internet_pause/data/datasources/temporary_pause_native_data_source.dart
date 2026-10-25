import 'package:flutter/services.dart';

import '../../../app_blocker/data/datasources/native_app_data_source.dart';

abstract class TemporaryPauseNativeDataSource {
  Future<void> syncTemporaryPauses(String pausesJson);
}

class TemporaryPauseNativeDataSourceImpl implements TemporaryPauseNativeDataSource {
  TemporaryPauseNativeDataSourceImpl({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.example.blocker/traffic';
  final MethodChannel _channel;

  @override
  Future<void> syncTemporaryPauses(String pausesJson) async {
    try {
      await _channel.invokeMethod<void>('syncTemporaryPauses', {
        'pauses': pausesJson,
      });
    } on PlatformException catch (error) {
      throw NativeDataSourceException(
        error.message ?? 'Unable to sync temporary pauses to native service',
      );
    }
  }
}
