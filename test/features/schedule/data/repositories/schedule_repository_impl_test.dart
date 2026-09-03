import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/schedule/data/datasources/schedule_local_data_source.dart';
import 'package:net_guard/features/schedule/data/datasources/schedule_native_data_source.dart';
import 'package:net_guard/features/schedule/data/models/schedule_model.dart';
import 'package:net_guard/features/schedule/data/repositories/schedule_repository_impl.dart';

class MockScheduleLocalDataSource extends Mock
    implements ScheduleLocalDataSource {}

class MockScheduleNativeDataSource extends Mock
    implements ScheduleNativeDataSource {}

class FakeScheduleModel extends Fake implements ScheduleModel {}

void main() {
  late MockScheduleLocalDataSource localDataSource;
  late MockScheduleNativeDataSource nativeDataSource;
  late ScheduleRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeScheduleModel());
  });

  const testModel = ScheduleModel(
    id: 's_test',
    name: 'Test Schedule',
    startTimeMinutes: 600,
    endTimeMinutes: 1200,
    activeDays: [1, 2, 3],
    targetPackages: ['com.test.app'],
    isEnabled: true,
  );

  setUp(() {
    localDataSource = MockScheduleLocalDataSource();
    nativeDataSource = MockScheduleNativeDataSource();
    repository = ScheduleRepositoryImpl(
      localDataSource: localDataSource,
      nativeDataSource: nativeDataSource,
    );

    when(() => nativeDataSource.syncActiveScheduledPackages(any()))
        .thenAnswer((_) async {});
  });

  group('ScheduleRepositoryImpl', () {
    test('getSchedules returns list of entities on success', () async {
      when(() => localDataSource.getSchedules())
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getSchedules();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should not fail'),
        (list) => expect(list.first.id, testModel.id),
      );
    });

    test('createSchedule calls local and syncs native', () async {
      when(() => localDataSource.createSchedule(any()))
          .thenAnswer((_) async => testModel);
      when(() => localDataSource.getSchedules())
          .thenAnswer((_) async => [testModel]);

      final result = await repository.createSchedule(testModel.toEntity());

      expect(result, Right(testModel.toEntity()));
      verify(() => localDataSource.createSchedule(any())).called(1);
      verify(() => nativeDataSource.syncActiveScheduledPackages(any())).called(1);
    });

    test('deleteSchedule deletes and syncs native', () async {
      when(() => localDataSource.deleteSchedule('s_test'))
          .thenAnswer((_) async {});
      when(() => localDataSource.getSchedules())
          .thenAnswer((_) async => []);

      final result = await repository.deleteSchedule('s_test');

      expect(result, const Right(null));
      verify(() => localDataSource.deleteSchedule('s_test')).called(1);
    });
  });
}
