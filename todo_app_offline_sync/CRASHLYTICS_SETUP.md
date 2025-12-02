# Firebase Crashlytics Setup Guide

This guide explains how to set up Firebase Crashlytics for crash reporting in the Todo App.

## What is Firebase Crashlytics?

Firebase Crashlytics is a lightweight, realtime crash reporter that helps you track, prioritize, and fix stability issues that erode your app quality. It provides:

- Automatic crash reporting
- Real-time alerts for new crashes
- Detailed crash reports with stack traces
- User impact metrics
- Custom logging and keys
- Free tier with generous limits

## Prerequisites

- Firebase project created
- Firebase configured in your app
- `google-services.json` in `android/app/`
- Flutter app running successfully

## Step 1: Enable Crashlytics in Firebase Console

### 1.1 Navigate to Crashlytics

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click "Crashlytics" in the left sidebar
4. Click "Get started" or "Enable Crashlytics"

### 1.2 Follow Setup Instructions

Firebase will guide you through:
1. Adding the Crashlytics SDK (we'll do this in Step 2)
2. Forcing a test crash (we'll do this in Step 5)
3. Waiting for crash data (takes a few minutes)

## Step 2: Add Crashlytics Dependencies

### 2.1 Update pubspec.yaml

The dependency is already added:

```yaml
dependencies:
  firebase_crashlytics: ^3.4.9
```

### 2.2 Install Dependencies

```bash
flutter pub get
```

## Step 3: Configure Android

### 3.1 Update build.gradle (Project Level)

Edit `android/build.gradle.kts`:

```kotlin
plugins {
    // ... existing plugins
    id("com.google.gms.google-services") version "4.4.0" apply false
    id("com.google.firebase.crashlytics") version "2.9.9" apply false
}
```

### 3.2 Update build.gradle (App Level)

Edit `android/app/build.gradle.kts`:

Add plugins at the top:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Add this
    id("com.google.firebase.crashlytics")  // Add this
}
```

### 3.3 Verify Configuration

The `google-services.json` file should already be in `android/app/`.

## Step 4: Initialize Crashlytics in Flutter

### 4.1 Update main.dart

Edit `lib/main.dart` to initialize Crashlytics:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Pass all uncaught errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(const MyApp());
}
```

### 4.2 Create Crashlytics Service

Create `lib/services/crashlytics_service.dart`:

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service for managing crash reporting and analytics
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initialize Crashlytics
  Future<void> initialize() async {
    // Enable Crashlytics collection
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    
    // Set up automatic crash reporting
    FlutterError.onError = _crashlytics.recordFlutterFatalError;
    
    // Catch errors in debug mode
    if (kDebugMode) {
      // In debug mode, print errors to console
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _crashlytics.recordFlutterFatalError(details);
      };
    }
  }

  /// Log a message to Crashlytics
  void log(String message) {
    _crashlytics.log(message);
  }

  /// Set user identifier
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  /// Set custom key-value pair
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// Record a non-fatal error
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
  }

  /// Force a crash (for testing only!)
  void forceCrash() {
    _crashlytics.crash();
  }

  /// Check if crash reporting is enabled
  Future<bool> isCrashlyticsCollectionEnabled() async {
    return await _crashlytics.isCrashlyticsCollectionEnabled();
  }
}
```

## Step 5: Test Crashlytics

### 5.1 Force a Test Crash

Add a test button to your app (temporary):

```dart
// In your debug screen or settings
ElevatedButton(
  onPressed: () {
    FirebaseCrashlytics.instance.crash();
  },
  child: Text('Test Crash'),
)
```

Or use the service:

```dart
final crashlytics = CrashlyticsService();
crashlytics.forceCrash();
```

### 5.2 Build and Run

```bash
# Build release version (Crashlytics works best in release mode)
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk

# Or run in release mode
flutter run --release
```

### 5.3 Trigger the Crash

1. Open the app
2. Tap the "Test Crash" button
3. App will crash immediately
4. Reopen the app (this sends the crash report)

### 5.4 View Crash in Console

1. Go to Firebase Console → Crashlytics
2. Wait 5-10 minutes for crash to appear
3. You should see the test crash with stack trace

## Step 6: Integrate with App

### 6.1 Initialize in Main

Update `lib/main.dart`:

```dart
import 'services/crashlytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Initialize Crashlytics
  final crashlytics = CrashlyticsService();
  await crashlytics.initialize();
  
  runApp(const MyApp());
}
```

### 6.2 Log User Actions

In your BLoCs or services:

```dart
final crashlytics = CrashlyticsService();

// Log important actions
crashlytics.log('User created task: ${task.title}');
crashlytics.log('Sync started');
crashlytics.log('Authentication successful');
```

### 6.3 Set User Context

When user signs in:

```dart
// In AuthBloc or AuthService
await crashlytics.setUserId(user.uid);
await crashlytics.setCustomKey('email', user.email);
await crashlytics.setCustomKey('displayName', user.displayName ?? 'Unknown');
```

### 6.4 Record Non-Fatal Errors

For caught exceptions:

```dart
try {
  await syncService.syncTasks();
} catch (e, stack) {
  // Log to Crashlytics
  await crashlytics.recordError(
    e,
    stack,
    reason: 'Sync failed',
    fatal: false,
  );
  
  // Show error to user
  emit(SyncError(e.toString()));
}
```

## Step 7: Custom Logging

### 7.1 Add Breadcrumbs

Log user journey:

```dart
// In TaskBloc
@override
Stream<TaskState> mapEventToState(TaskEvent event) async* {
  crashlytics.log('TaskEvent: ${event.runtimeType}');
  
  if (event is AddTask) {
    crashlytics.log('Adding task: ${event.title}');
    // ... handle event
  }
}
```

### 7.2 Add Custom Keys

Add context for debugging:

```dart
// Set app state
await crashlytics.setCustomKey('tasks_count', taskList.length);
await crashlytics.setCustomKey('is_synced', isSynced);
await crashlytics.setCustomKey('network_status', networkStatus);

// Set feature flags
await crashlytics.setCustomKey('feature_notifications', true);
await crashlytics.setCustomKey('feature_sync', true);
```

### 7.3 Track Critical Paths

```dart
// Before critical operation
crashlytics.log('Starting database migration');
await crashlytics.setCustomKey('migration_version', '1.0.0');

try {
  await database.migrate();
  crashlytics.log('Database migration successful');
} catch (e, stack) {
  crashlytics.log('Database migration failed');
  await crashlytics.recordError(e, stack, reason: 'Migration failed');
}
```

## Step 8: Production Configuration

### 8.1 Disable in Debug Mode (Optional)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Only enable in release mode
  if (kReleaseMode) {
    final crashlytics = CrashlyticsService();
    await crashlytics.initialize();
  }
  
  runApp(const MyApp());
}
```

### 8.2 Configure Collection

```dart
// Enable/disable based on user preference
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
  userConsent && kReleaseMode,
);
```

## Step 9: Monitor Crashes

### 9.1 Firebase Console

View crashes at: [https://console.firebase.google.com/](https://console.firebase.google.com/)

Navigate to: Crashlytics → Dashboard

### 9.2 Key Metrics

Monitor:
- **Crash-free users**: Percentage of users not experiencing crashes
- **Crash-free sessions**: Percentage of sessions without crashes
- **Crashes**: Total number of crashes
- **Impacted users**: Number of users affected

### 9.3 Crash Details

For each crash, view:
- Stack trace
- Device information
- OS version
- App version
- Custom keys and logs
- Number of occurrences
- Affected users

### 9.4 Set Up Alerts

1. Go to Crashlytics → Settings
2. Configure email alerts for:
   - New issues
   - Regressed issues
   - Velocity alerts (sudden spike in crashes)

## Step 10: Best Practices

### 10.1 Logging Guidelines

**Do Log**:
- User actions (create, edit, delete)
- State transitions
- API calls
- Authentication events
- Sync operations

**Don't Log**:
- Sensitive data (passwords, tokens)
- Personal information (unless anonymized)
- Large data payloads
- High-frequency events (every frame)

### 10.2 Custom Keys

Use custom keys for:
- App state (is_synced, is_authenticated)
- Feature flags (feature_x_enabled)
- User preferences (theme, language)
- Environment info (api_url, app_version)

### 10.3 Error Handling

```dart
// Good: Catch and log specific errors
try {
  await riskyOperation();
} on NetworkException catch (e, stack) {
  await crashlytics.recordError(e, stack, reason: 'Network error');
} on DatabaseException catch (e, stack) {
  await crashlytics.recordError(e, stack, reason: 'Database error');
}

// Bad: Catch all without logging
try {
  await riskyOperation();
} catch (e) {
  // Silent failure - no crash report!
}
```

### 10.4 Performance

- Don't log excessively (max ~100 logs per crash)
- Use custom keys instead of many logs
- Avoid logging in tight loops
- Batch operations when possible

## Troubleshooting

### Crashes Not Appearing

**Issue**: Crashes don't show up in console

**Solutions**:
1. Wait 5-10 minutes after crash
2. Reopen app to send crash report
3. Check internet connectivity
4. Verify Crashlytics is enabled
5. Check Firebase project is correct
6. Ensure `google-services.json` is correct

### Build Errors

**Issue**: Build fails with Crashlytics errors

**Solutions**:
1. Run `flutter clean && flutter pub get`
2. Verify plugin versions are compatible
3. Check `build.gradle.kts` syntax
4. Ensure Google Services plugin is applied

### Crashes in Debug Mode

**Issue**: App crashes in debug but not reported

**Solution**: Crashlytics works best in release mode
```bash
flutter run --release
```

### Missing Stack Traces

**Issue**: Crash reports show obfuscated stack traces

**Solution**: Upload debug symbols (automatic in Flutter)
- Flutter automatically uploads symbols
- For manual upload, see Firebase documentation

## Privacy Considerations

### User Consent

Consider asking for user consent:

```dart
// Show consent dialog
final consent = await showConsentDialog();

// Enable/disable based on consent
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(consent);
```

### Data Collection

Crashlytics collects:
- Crash stack traces
- Device information (model, OS version)
- App version
- Custom keys and logs
- User identifier (if set)

### Privacy Policy

Update your privacy policy to mention:
- Crash data collection
- Purpose (improving app stability)
- Data retention (90 days by default)
- User rights (opt-out option)

## Testing Checklist

- [ ] Crashlytics dependency added
- [ ] Firebase configured in Android
- [ ] Crashlytics initialized in main.dart
- [ ] Test crash triggered and reported
- [ ] Crash appears in Firebase Console
- [ ] User ID set on authentication
- [ ] Custom keys configured
- [ ] Non-fatal errors logged
- [ ] Breadcrumbs added for critical paths
- [ ] Privacy policy updated

## Production Checklist

- [ ] Crashlytics enabled in release builds
- [ ] Debug symbols uploaded (automatic)
- [ ] Email alerts configured
- [ ] Team members have access to console
- [ ] Monitoring dashboard bookmarked
- [ ] Response plan for critical crashes
- [ ] User consent implemented (if required)

## Monitoring Schedule

### Daily
- [ ] Check for new crashes
- [ ] Review crash-free users percentage
- [ ] Respond to critical crashes

### Weekly
- [ ] Review crash trends
- [ ] Prioritize fixes for top crashes
- [ ] Check for regressed issues

### Monthly
- [ ] Review overall stability metrics
- [ ] Update crash response procedures
- [ ] Train team on new crash patterns

## Support Resources

- **Crashlytics Documentation**: [https://firebase.google.com/docs/crashlytics](https://firebase.google.com/docs/crashlytics)
- **Flutter Crashlytics**: [https://firebase.flutter.dev/docs/crashlytics/overview](https://firebase.flutter.dev/docs/crashlytics/overview)
- **Firebase Console**: [https://console.firebase.google.com/](https://console.firebase.google.com/)
- **Stack Overflow**: [https://stackoverflow.com/questions/tagged/firebase-crashlytics](https://stackoverflow.com/questions/tagged/firebase-crashlytics)

## Example Implementation

See `lib/services/crashlytics_service.dart` for the complete implementation.

## Next Steps

After setup:
1. Monitor crashes for first week
2. Fix critical crashes immediately
3. Prioritize fixes based on user impact
4. Set up automated alerts
5. Review crash trends regularly
