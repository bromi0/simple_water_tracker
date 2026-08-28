import 'package:flutter_test/flutter_test.dart';
import 'package:simple_water_tracker/src/observability/app_observability.dart';

void main() {
  group('AppPerformance', () {
    test('logs a completed operation with elapsed time', () async {
      final records = <AppLogRecord>[];
      final performance = AppPerformance(
        logger: AppLogger(sink: records.add, enabled: true),
      );

      final result = await performance.measure('test.operation', () async => 7);

      expect(result, 7);
      expect(records, hasLength(1));
      expect(records.single.event, 'operation_completed');
      expect(records.single.fields['operation'], 'test.operation');
      expect(records.single.fields['elapsed_ms'], isA<double>());
    });

    test('logs and rethrows a failed operation', () async {
      final records = <AppLogRecord>[];
      final performance = AppPerformance(
        logger: AppLogger(sink: records.add, enabled: true),
      );

      await expectLater(
        performance.measure<void>('test.failure', () async {
          throw StateError('failed');
        }),
        throwsStateError,
      );

      expect(records, hasLength(1));
      expect(records.single.event, 'operation_failed');
      expect(records.single.error, isA<StateError>());
    });
  });

  test('AppLogRecord produces structured JSON', () {
    const record = AppLogRecord(
      level: AppLogLevel.info,
      event: 'example',
      fields: {'count': 2},
    );

    expect(record.message, '{"event":"example","count":2}');
  });
}
