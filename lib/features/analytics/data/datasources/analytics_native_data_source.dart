import 'package:flutter/services.dart';
import '../models/app_usage_model.dart';

class AnalyticsNativeDataSourceException implements Exception {
  const AnalyticsNativeDataSourceException(this.message);
  final String message;

  @override
  String toString() => 'AnalyticsNativeDataSourceException: $message';
}

abstract class AnalyticsNativeDataSource {
  Future<bool> checkUsagePermission();
  Future<void> requestUsagePermission();
  Future<AnalyticsSummaryModel> getAppUsageAnalytics(String timeRange);
}

class AnalyticsNativeDataSourceImpl implements AnalyticsNativeDataSource {
  AnalyticsNativeDataSourceImpl({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.app.net_guard/analytics');

  final MethodChannel _channel;

  @override
  Future<bool> checkUsagePermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkUsagePermission');
      return result ?? false;
    } on PlatformException catch (e) {
      throw AnalyticsNativeDataSourceException(
        e.message ?? 'Failed to check usage permission',
      );
    } catch (e) {
      throw AnalyticsNativeDataSourceException('Unexpected error checking permission: $e');
    }
  }

  @override
  Future<void> requestUsagePermission() async {
    try {
      await _channel.invokeMethod('requestUsagePermission');
    } on PlatformException catch (e) {
      throw AnalyticsNativeDataSourceException(
        e.message ?? 'Failed to request usage permission',
      );
    } catch (e) {
      throw AnalyticsNativeDataSourceException('Unexpected error requesting permission: $e');
    }
  }

  @override
  Future<AnalyticsSummaryModel> getAppUsageAnalytics(String timeRange) async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'getAppUsageAnalytics',
        {'timeRange': timeRange},
      );

      if (result is Map) {
        return AnalyticsSummaryModel.fromMap(result);
      } else if (result is List) {
        return AnalyticsSummaryModel.fromMap({
          'appUsages': result,
          'dailyScreenTimeSeconds': <int>[],
          'dailyLabels': <String>[],
          'totalScreenTimeSeconds': 0,
          'totalDataBytes': 0,
        });
      } else {
        throw const AnalyticsNativeDataSourceException('Invalid response format from analytics platform channel');
      }
    } on PlatformException catch (e) {
      throw AnalyticsNativeDataSourceException(
        e.message ?? 'Failed to retrieve app usage analytics',
      );
    } catch (e) {
      if (e is AnalyticsNativeDataSourceException) rethrow;
      throw AnalyticsNativeDataSourceException('Unexpected error retrieving analytics: $e');
    }
  }
}
