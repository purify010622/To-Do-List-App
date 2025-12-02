import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor network connectivity status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<bool>? _subscription;
  
  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return _isConnected(results);
    });
  }
  
  /// Check if device is currently connected to internet
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }
  
  /// Helper to determine if connectivity results indicate connection
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
  }
  
  /// Start monitoring connectivity changes
  void startMonitoring(Function(bool isConnected) onConnectivityChanged) {
    _subscription = connectivityStream.listen(onConnectivityChanged);
  }
  
  /// Stop monitoring connectivity changes
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }
  
  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
