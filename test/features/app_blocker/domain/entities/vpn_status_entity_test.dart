import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/domain/entities/vpn_status_entity.dart';

void main() {
  group('VpnStatus', () {
    test('fromString parses correctly', () {
      expect(VpnStatus.fromString('active'), VpnStatus.active);
      expect(VpnStatus.fromString('ACTIVE'), VpnStatus.active);
      expect(VpnStatus.fromString('restarting'), VpnStatus.restarting);
      expect(VpnStatus.fromString('RESTARTING'), VpnStatus.restarting);
      expect(VpnStatus.fromString('inactive'), VpnStatus.inactive);
      expect(VpnStatus.fromString('unknown'), VpnStatus.inactive);
      expect(VpnStatus.fromString(null), VpnStatus.inactive);
    });
  });

  group('VpnStatusInfo', () {
    test('fromMap parses map correctly', () {
      final map = {
        'status': 'active',
        'blockedCount': 5,
        'reason': 'Testing',
      };
      final info = VpnStatusInfo.fromMap(map);
      expect(info.status, VpnStatus.active);
      expect(info.blockedCount, 5);
      expect(info.reason, 'Testing');
    });

    test('fromMap handles missing or null fields', () {
      final info = VpnStatusInfo.fromMap({});
      expect(info.status, VpnStatus.inactive);
      expect(info.blockedCount, 0);
      expect(info.reason, isNull);
    });

    test('supports value equality', () {
      const info1 = VpnStatusInfo(
        status: VpnStatus.active,
        blockedCount: 3,
        reason: 'ok',
      );
      const info2 = VpnStatusInfo(
        status: VpnStatus.active,
        blockedCount: 3,
        reason: 'ok',
      );
      const info3 = VpnStatusInfo(
        status: VpnStatus.inactive,
        blockedCount: 0,
      );

      expect(info1, equals(info2));
      expect(info1.hashCode, equals(info2.hashCode));
      expect(info1, isNot(equals(info3)));
    });
  });
}
