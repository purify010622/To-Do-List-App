import 'dart:async';

/// Utility class for debouncing function calls
/// Useful for search/filter operations to reduce unnecessary processing
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Call the provided function after the delay
  /// If called again before the delay expires, the previous call is cancelled
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending debounced calls
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose of the debouncer
  void dispose() {
    _timer?.cancel();
  }
}
