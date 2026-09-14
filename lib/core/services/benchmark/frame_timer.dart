// lib/core/benchmark/frame_timer.dart
//
// PURPOSE:
//   Tracks frame rendering times during a measured action.
//   Flutter calls addTimingsCallback after every frame with a list
//   of FrameTiming objects — each one contains build + raster duration.
//
// WHAT IT MEASURES:
//   worstFrameMs — the single slowest frame during the action.
//   The 60fps budget is 16.7ms per frame. Any frame over that is a jank.
//   This is where rebuild count directly translates to visible stutter.
//
// LIFECYCLE:
//   The callback is registered ONCE on first use and stays attached for
//   the rest of the run. This is critical: addTimingsCallback delivery
//   from the engine is batched and lags 50–100ms behind real time on
//   Android, so removing the callback right after an action completes
//   loses the very timings we care about.
//
//   1. startTracking()  — snapshots a "start frame index" and resets max
//   2. action runs      — engine renders frames; callback fires later
//   3. awaitSettledFrame() — waits long enough for the engine to flush
//                            timings for frames produced during the action
//   4. read worstFrameMs
//
// NOTE:
//   addTimingsCallback is available in both debug and profile builds.
//   In release builds frame timings are less precise but still usable
//   for relative comparison between libraries.

import 'package:flutter/scheduler.dart';

class FrameTimer {
  double _worstFrameMs = 0.0;
  bool _tracking = false;
  bool _callbackRegistered = false;

  /// Worst single frame time recorded since startTracking(), in ms.
  double get worstFrameMs => _worstFrameMs;

  /// Begin recording frame timings.
  void startTracking() {
    _worstFrameMs = 0.0;
    _tracking = true;
    if (!_callbackRegistered) {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
      _callbackRegistered = true;
    }
  }

  /// Stop accepting new timings into the current window.
  /// The callback itself stays registered — see lifecycle note above.
  void stopTracking() {
    _tracking = false;
  }

  /// Waits for the next frame to finish rendering after the action.
  /// Defines the end of the user-visible measurement window — call
  /// snapshot durationMs *after* this returns and *before* [flushTimings].
  Future<void> awaitSettledFrame() async {
    await SchedulerBinding.instance.endOfFrame;
    await Future.delayed(Duration.zero);
  }

  /// Gives the engine time to deliver pending FrameTiming callbacks
  /// for frames produced during the measurement window, then stops
  /// accepting new timings. On Android, FrameTiming callbacks arrive
  /// in batches with a ~50–100ms lag — without this delay, timings
  /// for fast operations never arrive before tracking stops and
  /// worstFrameMs stays at 0.
  ///
  /// This delay is intentionally NOT included in durationMs.
  Future<void> flushTimings() async {
    await Future.delayed(const Duration(milliseconds: 120));
    stopTracking();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!_tracking) return;
    for (final timing in timings) {
      // totalSpan = build + layout + paint + raster — the full frame cost
      final ms = timing.totalSpan.inMicroseconds / 1000.0;
      if (ms > _worstFrameMs) _worstFrameMs = ms;
    }
  }
}
