import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service for managing crash reporting and analytics
/// 
/// This service wraps Firebase Crashlytics to provide:
/// - Automatic crash reporting
/// - Custom logging and breadcrumbs
/// - User context tracking
/// - Non-fatal error reporting
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initialize Crashlytics
  /// 
  /// Sets up automatic crash reporting and error handling.
  /// Should be called early in app initialization.
  Future<void> initialize() async {
    // Enable Crashlytics collection
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    
    // Set up automatic crash reporting for Flutter errors
    FlutterError.onError = _crashlytics.recordFlutterFatalError;
    
    // In debug mode, also print errors to console
    if (kDebugMode) {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _crashlytics.recordFlutterFatalError(details);
      };
    }
    
    log('Crashlytics initialized');
  }

  /// Log a message to Crashlytics
  /// 
  /// Use this to add breadcrumbs that help debug crashes.
  /// Messages are included in crash reports.
  /// 
  /// Example:
  /// ```dart
  /// crashlytics.log('User created task: Buy groceries');
  /// crashlytics.log('Sync started');
  /// ```
  void log(String message) {
    _crashlytics.log(message);
    if (kDebugMode) {
      debugPrint('[Crashlytics] $message');
    }
  }

  /// Set user identifier
  /// 
  /// Associates crashes with a specific user.
  /// Call this when user signs in.
  /// 
  /// Example:
  /// ```dart
  /// await crashlytics.setUserId(user.uid);
  /// ```
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
    log('User ID set: $userId');
  }

  /// Clear user identifier
  /// 
  /// Call this when user signs out.
  Future<void> clearUserId() async {
    await _crashlytics.setUserIdentifier('');
    log('User ID cleared');
  }

  /// Set custom key-value pair
  /// 
  /// Adds context to crash reports.
  /// Use for app state, feature flags, etc.
  /// 
  /// Example:
  /// ```dart
  /// await crashlytics.setCustomKey('tasks_count', 42);
  /// await crashlytics.setCustomKey('is_synced', true);
  /// await crashlytics.setCustomKey('theme', 'dark');
  /// ```
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// Set multiple custom keys at once
  /// 
  /// Example:
  /// ```dart
  /// await crashlytics.setCustomKeys({
  ///   'tasks_count': 42,
  ///   'is_synced': true,
  ///   'network_status': 'online',
  /// });
  /// ```
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    for (final entry in keys.entries) {
      await setCustomKey(entry.key, entry.value);
    }
  }

  /// Record a non-fatal error
  /// 
  /// Use this for caught exceptions that you want to track.
  /// 
  /// Parameters:
  /// - [exception]: The exception object
  /// - [stack]: Stack trace (optional)
  /// - [reason]: Human-readable reason (optional)
  /// - [fatal]: Whether this should be treated as fatal (default: false)
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await syncService.syncTasks();
  /// } catch (e, stack) {
  ///   await crashlytics.recordError(
  ///     e,
  ///     stack,
  ///     reason: 'Sync failed',
  ///     fatal: false,
  ///   );
  /// }
  /// ```
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
    
    if (kDebugMode) {
      debugPrint('[Crashlytics] Error recorded: $exception');
      if (reason != null) {
        debugPrint('[Crashlytics] Reason: $reason');
      }
    }
  }

  /// Record a Flutter error
  /// 
  /// Use this for FlutterErrorDetails objects.
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await _crashlytics.recordFlutterFatalError(details);
  }

  /// Force a crash (for testing only!)
  /// 
  /// This will immediately crash the app.
  /// Use only for testing Crashlytics integration.
  /// 
  /// Example:
  /// ```dart
  /// // In debug settings screen
  /// ElevatedButton(
  ///   onPressed: () => crashlytics.forceCrash(),
  ///   child: Text('Test Crash'),
  /// )
  /// ```
  void forceCrash() {
    log('Force crash triggered');
    _crashlytics.crash();
  }

  /// Check if crash reporting is enabled
  Future<bool> isCrashlyticsCollectionEnabled() async {
    return _crashlytics.isCrashlyticsCollectionEnabled;
  }

  /// Enable or disable crash reporting
  /// 
  /// Use this to respect user privacy preferences.
  /// 
  /// Example:
  /// ```dart
  /// await crashlytics.setCrashlyticsCollectionEnabled(userConsent);
  /// ```
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    log('Crashlytics collection ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if app crashed on previous execution
  Future<bool> didCrashOnPreviousExecution() async {
    return await _crashlytics.didCrashOnPreviousExecution();
  }

  /// Send unsent crash reports
  /// 
  /// Crashlytics automatically sends reports, but you can
  /// manually trigger sending with this method.
  Future<void> sendUnsentReports() async {
    await _crashlytics.sendUnsentReports();
    log('Unsent reports sent');
  }

  /// Delete unsent crash reports
  /// 
  /// Use this if user opts out of crash reporting.
  Future<void> deleteUnsentReports() async {
    await _crashlytics.deleteUnsentReports();
    log('Unsent reports deleted');
  }
}
