import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain_filter_model.dart';

abstract class DomainLocalDataSource {
  Future<List<DomainFilterModel>> getDomains();
  Future<void> saveDomains(List<DomainFilterModel> domains);
  Future<DomainFilterModel> addDomain(String domain);
  Future<DomainFilterModel> toggleDomain(String id, bool isBlocked);
  Future<void> removeDomain(String id);
}

class DomainLocalDataSourceImpl implements DomainLocalDataSource {
  DomainLocalDataSourceImpl(this._preferences);

  final SharedPreferences _preferences;
  static const String blockedDomainsKey = 'net_guard_blocked_domains';

  @override
  Future<List<DomainFilterModel>> getDomains() async {
    final jsonString = _preferences.getString(blockedDomainsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return const [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => DomainFilterModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DomainLocalDataSourceException('Failed to decode domains from local storage: $e');
    }
  }

  @override
  Future<void> saveDomains(List<DomainFilterModel> domains) async {
    final encoded = jsonEncode(domains.map((d) => d.toJson()).toList());
    final success = await _preferences.setString(blockedDomainsKey, encoded);
    if (!success) {
      throw const DomainLocalDataSourceException('Failed to save domains to local storage');
    }
  }

  @override
  Future<DomainFilterModel> addDomain(String domain) async {
    final sanitized = domain.trim().toLowerCase();
    if (sanitized.isEmpty) {
      throw const DomainLocalDataSourceException('Domain cannot be empty');
    }
    final current = await getDomains();
    if (current.any((d) => d.domain.toLowerCase() == sanitized)) {
      throw const DomainLocalDataSourceException('Domain is already added');
    }

    final newModel = DomainFilterModel(
      id: 'domain_${DateTime.now().millisecondsSinceEpoch}',
      domain: sanitized,
      isBlocked: true,
      createdAt: DateTime.now(),
    );

    final updated = [...current, newModel];
    await saveDomains(updated);
    return newModel;
  }

  @override
  Future<DomainFilterModel> toggleDomain(String id, bool isBlocked) async {
    final current = await getDomains();
    final index = current.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw const DomainLocalDataSourceException('Domain not found');
    }

    final updatedModel = current[index].copyWith(isBlocked: isBlocked);
    current[index] = updatedModel;
    await saveDomains(current);
    return updatedModel;
  }

  @override
  Future<void> removeDomain(String id) async {
    final current = await getDomains();
    final updated = current.where((d) => d.id != id).toList();
    await saveDomains(updated);
  }
}

class DomainLocalDataSourceException implements Exception {
  const DomainLocalDataSourceException(this.message);
  final String message;

  @override
  String toString() => message;
}
