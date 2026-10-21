import 'package:installed_apps/installed_apps.dart';

import '../models/app_info_model.dart';

abstract class InstalledAppsGateway {
  Future<List<AppInfo>> getUserLaunchableApps();
}

class InstalledAppsGatewayImpl implements InstalledAppsGateway {
  @override
  Future<List<AppInfo>> getUserLaunchableApps() =>
      InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
        withIcon: true,
      );
}

abstract class InstalledAppsDataSource {
  Future<List<AppInfoModel>> getInstalledApps();
}

class InstalledAppsDataSourceImpl implements InstalledAppsDataSource {
  InstalledAppsDataSourceImpl(this._gateway);

  final InstalledAppsGateway _gateway;

  @override
  Future<List<AppInfoModel>> getInstalledApps() async {
    try {
      final apps = await _gateway.getUserLaunchableApps();
      return apps
          .map(
            (app) => AppInfoModel(
              appName: app.name,
              packageName: app.packageName,
              isBlocked: false,
              iconBytes: app.icon,
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw InstalledAppsException(
        'Unable to fetch installed applications: $error',
      );
    }
  }
}

class InstalledAppsException implements Exception {
  const InstalledAppsException(this.message);
  final String message;
}
