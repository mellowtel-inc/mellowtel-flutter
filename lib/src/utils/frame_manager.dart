import 'dart:async';
import 'package:flutter/scheduler.dart';

class FrameManager {
  static final FrameManager _instance = FrameManager._internal();
  final Duration _maxWaitTime = const Duration(seconds: 5);
  final Duration _maximalBuildTime =
      const Duration(milliseconds: 11); // Example threshold
  final Map<DateTime, FrameTiming> _frameTimings = {};

  factory FrameManager() {
    return _instance;
  }

  FrameManager._internal() {
    SchedulerBinding.instance.addTimingsCallback(_frameCallback);
  }

  void _frameCallback(List<FrameTiming> timings) {
    _frameTimings.clear();
    final DateTime now = DateTime.now();
    for (var timing in timings) {
      _frameTimings[now] = timing;
    }
  }

  /// This method evaluates the last batch of frames to decide the idle state of device.
  /// 
  /// Works most appropriately for release builds because of reporting time of roughly 1s.
  Future<void> waitForIdleFrames() async {
    final Completer<void> completer = Completer<void>();
    final Stopwatch stopwatch = Stopwatch()..start();

    while (true) {
      if (_isIdle() || stopwatch.elapsed >= _maxWaitTime) {
        completer.complete();
        break;
      }
      await Future.delayed(
          const Duration(milliseconds: 100)); // Polling interval
    }

    return completer.future;
  }

  bool _isIdle() {
    if (_frameTimings.isEmpty) return true;

    for (var timing in _frameTimings.values) {
      if (timing.rasterDuration > _maximalBuildTime) {
        return false;
      }
    }
    return true;
  }
}
