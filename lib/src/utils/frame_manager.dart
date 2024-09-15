import 'dart:async';
import 'package:flutter/scheduler.dart';

class FrameManager {
  final Duration _maxWaitTime = const Duration(seconds: 5);
  final Duration _maximalBuildTime =
      const Duration(milliseconds: 11); // Example threshold

  Future<void> waitForIdleFrames() async {
    final Completer<void> completer = Completer<void>();
    final Stopwatch stopwatch = Stopwatch()..start();

    while (true) {
      Completer<bool> idleCheckerCompletor = Completer<bool>();
      callback(data) => idleChecker(idleCheckerCompletor, data);

      SchedulerBinding.instance.addTimingsCallback(callback);

      final bool isIdle = await idleCheckerCompletor.future;

      SchedulerBinding.instance.removeTimingsCallback(callback);

      if (isIdle || stopwatch.elapsed >= _maxWaitTime) {
        completer.complete();
        break;
      }
    }

    return completer.future;
  }

  void idleChecker(Completer<bool> completor, List<FrameTiming> timings) {
    print(timings);
    if (timings.isEmpty) return completor.complete(true);

    // Return not idle if any frame took more time than the maximalBuildTime
    for (var frame in timings) {
      if (frame.rasterDuration > _maximalBuildTime) {
        print("NOT TAKING");
        return completor.complete(false);
      }
    }
    return completor.complete(true);
  }
}
