import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerState {
  const TimerState({
    this.elapsedMs = 0,
    this.isRunning = false,
    this.anchorTime,
    this.baseElapsedMs = 0,
  });

  final int elapsedMs;
  final bool isRunning;
  final DateTime? anchorTime;
  final int baseElapsedMs;

  TimerState copyWith({
    int? elapsedMs,
    bool? isRunning,
    DateTime? anchorTime,
    int? baseElapsedMs,
    bool clearAnchor = false,
  }) {
    return TimerState(
      elapsedMs: elapsedMs ?? this.elapsedMs,
      isRunning: isRunning ?? this.isRunning,
      anchorTime: clearAnchor ? null : anchorTime ?? this.anchorTime,
      baseElapsedMs: baseElapsedMs ?? this.baseElapsedMs,
    );
  }
}

final timerProvider =
    StateNotifierProvider.autoDispose<TimerNotifier, TimerState>(
  (ref) => TimerNotifier(),
);

class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier() : super(const TimerState());

  Timer? _ticker;

  void syncFromSessionStart(DateTime? startedAt, {int baseElapsedMs = 0}) {
    if (startedAt == null) {
      return;
    }

    final elapsed =
        baseElapsedMs + DateTime.now().difference(startedAt).inMilliseconds;
    state = TimerState(
      elapsedMs: elapsed,
      isRunning: true,
      anchorTime: DateTime.now(),
      baseElapsedMs: elapsed,
    );
    _startTicker();
  }

  void setElapsed(int elapsedMs) {
    _stopTicker();
    state = TimerState(
      elapsedMs: elapsedMs,
      baseElapsedMs: elapsedMs,
    );
  }

  void start() {
    if (state.isRunning) {
      return;
    }

    state = TimerState(
      elapsedMs: state.elapsedMs,
      isRunning: true,
      anchorTime: DateTime.now(),
      baseElapsedMs: state.elapsedMs,
    );
    _startTicker();
  }

  void stop() {
    _stopTicker();
    state = state.copyWith(isRunning: false, clearAnchor: true);
  }

  void reset() {
    _stopTicker();
    state = const TimerState();
  }

  int get currentElapsedMs {
    if (!state.isRunning || state.anchorTime == null) {
      return state.elapsedMs;
    }
    final delta = DateTime.now().difference(state.anchorTime!).inMilliseconds;
    return state.baseElapsedMs + delta;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!state.isRunning) {
        return;
      }
      state = state.copyWith(elapsedMs: currentElapsedMs);
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (state.isRunning && state.anchorTime != null) {
      state = state.copyWith(
        elapsedMs: currentElapsedMs,
        baseElapsedMs: currentElapsedMs,
        clearAnchor: true,
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
