import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

typedef AppLogSink = void Function(AppLogRecord record);

enum AppLogLevel { info, error }

class AppLogRecord {
  const AppLogRecord({
    required this.level,
    required this.event,
    this.fields = const {},
    this.error,
    this.stackTrace,
  });

  final AppLogLevel level;
  final String event;
  final Map<String, Object?> fields;
  final Object? error;
  final StackTrace? stackTrace;

  String get message => jsonEncode({
    'event': event,
    ...fields,
    if (error != null) 'error': error.toString(),
  });
}

/// Lightweight structured logging for local debugging and profile runs.
///
/// Logs are intentionally disabled in release builds. Fields must be safe to
/// write to a developer log and JSON-encodable; never include plant names,
/// picture paths, or other user data.
class AppLogger {
  AppLogger({AppLogSink? sink, bool? enabled})
    : _sink = sink ?? _developerLogSink,
      enabled = enabled ?? !kReleaseMode;

  final AppLogSink _sink;
  final bool enabled;

  void info(String event, {Map<String, Object?> fields = const {}}) {
    _write(AppLogRecord(level: AppLogLevel.info, event: event, fields: fields));
  }

  void error(
    String event, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write(
      AppLogRecord(
        level: AppLogLevel.error,
        event: event,
        fields: fields,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  void _write(AppLogRecord record) {
    if (enabled) _sink(record);
  }

  static void _developerLogSink(AppLogRecord record) {
    // developer.log feeds DevTools, while debugPrint makes the same record
    // available in Android logcat during an attached or standalone profile run.
    debugPrint('[simple_water_tracker] ${record.message}');
    if (record.stackTrace != null) {
      debugPrintStack(stackTrace: record.stackTrace);
    }
    developer.log(
      record.message,
      name: 'simple_water_tracker',
      level: record.level == AppLogLevel.error ? 1000 : 800,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }
}

/// Measures operations in both structured logs and the Dart/Flutter timeline.
class AppPerformance {
  AppPerformance({AppLogger? logger}) : _logger = logger ?? AppLogger();

  final AppLogger _logger;

  AppPerformanceOperation start(
    String operation, {
    Map<String, Object?> fields = const {},
  }) {
    return AppPerformanceOperation._(
      operation: operation,
      fields: fields,
      logger: _logger,
    );
  }

  Future<T> measure<T>(
    String operation,
    Future<T> Function() body, {
    Map<String, Object?> fields = const {},
  }) async {
    final measurement = start(operation, fields: fields);
    try {
      final result = await body();
      measurement.complete();
      return result;
    } catch (error, stackTrace) {
      measurement.fail(error, stackTrace);
      rethrow;
    }
  }

  T measureSync<T>(
    String operation,
    T Function() body, {
    Map<String, Object?> fields = const {},
  }) {
    final measurement = start(operation, fields: fields);
    try {
      final result = body();
      measurement.complete();
      return result;
    } catch (error, stackTrace) {
      measurement.fail(error, stackTrace);
      rethrow;
    }
  }
}

class AppPerformanceOperation {
  AppPerformanceOperation._({
    required this.operation,
    required Map<String, Object?> fields,
    required this._logger,
  }) : _fields = fields,
       _task = developer.TimelineTask()..start(operation, arguments: fields),
       _stopwatch = Stopwatch()..start();

  final String operation;
  final Map<String, Object?> _fields;
  final AppLogger _logger;
  final developer.TimelineTask _task;
  final Stopwatch _stopwatch;
  bool _finished = false;

  void complete({Map<String, Object?> fields = const {}}) {
    _finish(succeeded: true, fields: fields);
  }

  void fail(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?> fields = const {},
  }) {
    _finish(
      succeeded: false,
      fields: fields,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _finish({
    required bool succeeded,
    required Map<String, Object?> fields,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_finished) return;
    _finished = true;
    _stopwatch.stop();
    final completedFields = {
      ..._fields,
      ...fields,
      'operation': operation,
      'elapsed_ms': _stopwatch.elapsedMicroseconds / 1000,
    };
    _task.finish(
      arguments: {...completedFields, 'status': succeeded ? 'ok' : 'error'},
    );
    if (succeeded) {
      _logger.info('operation_completed', fields: completedFields);
    } else {
      _logger.error(
        'operation_failed',
        fields: completedFields,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final appLogger = AppLogger();
final appPerformance = AppPerformance(logger: appLogger);
