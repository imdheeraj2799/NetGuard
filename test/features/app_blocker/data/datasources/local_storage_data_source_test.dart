import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/data/datasources/local_storage_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('returns an empty list when no cache exists', () async {
    final preferences = await SharedPreferences.getInstance();
    final dataSource = LocalStorageDataSourceImpl(preferences);

    expect(await dataSource.getBlockedPackages(), isEmpty);
  });

  test('persists unique blocked package names', () async {
    final preferences = await SharedPreferences.getInstance();
    final dataSource = LocalStorageDataSourceImpl(preferences);

    await dataSource.setBlockedPackages(['mail', 'maps', 'mail']);

    expect(
      await dataSource.getBlockedPackages(),
      unorderedEquals(['mail', 'maps']),
    );
  });
}
