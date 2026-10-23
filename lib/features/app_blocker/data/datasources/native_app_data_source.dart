import 'package:flutter/services.dart';

import '../../domain/entities/vpn_status_entity.dart';

abstract class NativeAppDataSource {
  Future<void> updateBlockedList(List<String> blockedPackages);
  Future<void> stopVpnService();
  Future<VpnStatusInfo> getVpnStatus();
  Stream<VpnStatusInfo> get vpnStatusStream;
  Future<void> restartVpn();
  Future<void> syncSchedules(String schedulesJson);
  Future<bool> canScheduleExactAlarms();
  Future<bool> requestExactAlarmPermission();
  Future<bool> areNotificationsEnabled();
  Future<bool> requestNotificationPermission();
  Future<Map<String, dynamic>?> getInitialNotificationPayload();
}

class NativeAppDataSourceImpl implements NativeAppDataSource {
  NativeAppDataSourceImpl({
    MethodChannel? channel,
    EventChannel? statusChannel,
  })  : _channel = channel ?? const MethodChannel(_channelName),
        _statusChannel = statusChannel ?? const EventChannel(_statusChannelName);

  static const _channelName = 'com.example.blocker/traffic';
  static const _statusChannelName = 'com.app.net_guard/vpn_status';

  final MethodChannel _channel;
  final EventChannel _statusChannel;

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

  @override
  Future<VpnStatusInfo> getVpnStatus() async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>('getVpnStatus');
      if (result != null) {
        return VpnStatusInfo.fromMap(result);
      }
      return const VpnStatusInfo(status: VpnStatus.inactive);
    } on PlatformException catch (error) {
      throw NativeDataSourceException(
        error.message ?? 'Unable to get VPN status',
      );
    } catch (error) {
      throw NativeDataSourceException('Unable to get VPN status: $error');
    }
  }

  @override
  Stream<VpnStatusInfo> get vpnStatusStream {
    try {
      return _statusChannel
          .receiveBroadcastStream()
          .where((event) => event is Map)
          .map((event) => VpnStatusInfo.fromMap(event as Map<dynamic, dynamic>));
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Future<void> restartVpn() async {
    try {
      await _channel.invokeMethod<void>('restartVpn');
    } on PlatformException catch (error) {
      throw NativeDataSourceException(
        error.message ?? 'Unable to restart VPN service',
      );
    }
  }

  @override
  Future<void> syncSchedules(String schedulesJson) async {
    try {
      await _channel.invokeMethod<void>('syncSchedules', {
        'schedules': schedulesJson,
      });
    } on PlatformException catch (error) {
      throw NativeDataSourceException(
        error.message ?? 'Unable to sync schedules to background service',
      );
    }
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    try {
      final result = await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return result ?? true;
    } on PlatformException {
      return true;
    }
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestExactAlarmPermission');
      return result ?? true;
    } on PlatformException catch (error) {
      throw NativeDataSourceException(
        error.message ?? 'Unable to request exact alarm permission',
      );
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('areNotificationsEnabled');
      return result ?? true;
    } on PlatformException {
      return true;
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return result ?? true;
    } on PlatformException catch (error) {
      throw NativeDataSourceException(
        error.message ?? 'Unable to request notification permission',
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getInitialNotificationPayload() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getInitialNotificationPayload');
      return result;
    } on PlatformException {
      return null;
    }
  }
}

class NativeDataSourceException implements Exception {
  const NativeDataSourceException(this.message);
  final String message;
}
