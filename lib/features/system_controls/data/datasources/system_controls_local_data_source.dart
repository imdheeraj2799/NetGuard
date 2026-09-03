import 'package:shared_preferences/shared_preferences.dart';

abstract class SystemControlsLocalDataSource {
  Future<String> getSelectedDnsId();
  Future<void> setSelectedDnsId(String id);
  Future<String?> getCustomDnsIp();
  Future<void> setCustomDnsIp(String ip);
}

class SystemControlsLocalDataSourceImpl
    implements SystemControlsLocalDataSource {
  const SystemControlsLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _keySelectedDnsId = 'net_guard_selected_dns_id';
  static const _keyCustomDnsIp = 'net_guard_custom_dns_ip';

  @override
  Future<String> getSelectedDnsId() async {
    return _prefs.getString(_keySelectedDnsId) ?? 'cloudflare';
  }

  @override
  Future<void> setSelectedDnsId(String id) {
    return _prefs.setString(_keySelectedDnsId, id);
  }

  @override
  Future<String?> getCustomDnsIp() async {
    return _prefs.getString(_keyCustomDnsIp);
  }

  @override
  Future<void> setCustomDnsIp(String ip) {
    return _prefs.setString(_keyCustomDnsIp, ip.trim());
  }
}
