import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/domain_filter/data/models/domain_filter_model.dart';
import 'package:net_guard/features/domain_filter/domain/entities/blocked_domain_entity.dart';

void main() {
  final testDate = DateTime.parse('2026-01-01T12:00:00.000Z');
  final testModel = DomainFilterModel(
    id: 'domain_1',
    domain: 'youtube.com',
    isBlocked: true,
    createdAt: testDate,
  );

  test('DomainFilterModel serializes to JSON correctly', () {
    final json = testModel.toJson();
    expect(json['id'], 'domain_1');
    expect(json['domain'], 'youtube.com');
    expect(json['isBlocked'], true);
    expect(json['createdAt'], testDate.toIso8601String());
  });

  test('DomainFilterModel deserializes from JSON correctly', () {
    final json = {
      'id': 'domain_1',
      'domain': 'youtube.com',
      'isBlocked': true,
      'createdAt': testDate.toIso8601String(),
    };
    final model = DomainFilterModel.fromJson(json);
    expect(model.id, testModel.id);
    expect(model.domain, testModel.domain);
    expect(model.isBlocked, testModel.isBlocked);
    expect(model.createdAt, testModel.createdAt);
  });

  test('DomainFilterModel converts to and from BlockedDomainEntity', () {
    final entity = testModel.toEntity();
    expect(entity, isA<BlockedDomainEntity>());
    expect(entity.id, testModel.id);

    final fromEntity = DomainFilterModel.fromEntity(entity);
    expect(fromEntity, testModel);
  });
}
