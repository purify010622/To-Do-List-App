# Flutter App Production Deployment Guide

This guide explains how to configure and deploy the Todo App Flutter application for production use.

## Prerequisites

- Backend API deployed and accessible (see backend/DEPLOYMENT_GUIDE.md)
- Production API URL obtained (e.g., `https://your-app.onrender.com`)
- Firebase project configured
- Flutter SDK installed (3.x or later)
- Android Studio or Xcode for building

## Step 1: Update API Configuration

### 1.1 Update Production URL

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  /// Environment type
  static const Environment environment = Environment.production; // Change to production

  /// API base URL based on environment
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://localhost:3000/api';
      case Environment.production:
        return 'https://your-actual-app.onrender.com/api'; // Update this!
    }
  }
  // ... rest of the file
}
```

**Important**: Replace `https://your-actual-app.onrender.com/api` with your actual deployed backend URL.

### 1.2 Verify Configuration

The configuration should:
- Point to your production backend URL
- Include `/api` at the end of the URL
- Use `https://` (not `http://`)
- Match the URL from your hosting service (Render/Railway/Fly.io)

Examples:
- Render: `https://todo-app-backend.onrender.com/api`
- Railway: `https://todo-app-backend.railway.app/api`
- Fly.io: `https://todo-app-backend.fly.dev/api`

## Step 2: Update Backend CORS Configuration

Ensure your backend allows requests from the mobile app.

### 2.1 Update Backend Environment Variables

In your hosting service (Render/Railway/Fly.io), update `ALLOWED_ORIGINS`:

```
ALLOWED_ORIGINS=capacitor://localhost,ionic://localhost,https://yourdomain.com
```

For mobile apps, the important origins are:
- `capacitor://localhost` - For Capacitor apps
- `ionic://localhost` - For Ionic apps
- `http://localhost` - For development

### 2.2 Verify CORS Settings

Test CORS by making a request from your app:

```bash
# Test from command line
curl -X OPTIONS https://your-app.onrender.com/api/tasks \
  -H "Origin: capacitor://localhost" \
  -H "Access-Control-Request-Method: GET" \
  -v
```

Look for `Access-Control-Allow-Origin` header in response.

## Step 3: Test API Connection

Before building the release, test the API connection:

### 3.1 Run in Debug Mode

```bash
cd todo_app_offline_sync
flutter run
```

### 3.2 Test Authentication

1. Sign in with Google
2. Check logs for API calls
3. Verify no CORS errors
4. Confirm sync works

### 3.3 Test Sync Operations

1. Create a task
2. Trigger sync
3. Check backend logs for incoming requests
4. Verify task appears in MongoDB Atlas

### 3.4 Check Logs

Look for successful API calls:
```
✓ Successfully connected to API
✓ Authentication successful
✓ Sync completed: 5 tasks uploaded
```

Look for errors:
```
✗ CORS error - Update ALLOWED_ORIGINS
✗ Connection timeout - Check API URL
✗ 401 Unauthorized - Check Firebase config
```

## Step 4: Configure Firebase for Production

### 4.1 Android Configuration

Ensure `android/app/google-services.json` is present and configured for your Firebase project.

### 4.2 iOS Configuration (if building for iOS)

Ensure `ios/Runner/GoogleService-Info.plist` is present and configured.

### 4.3 Verify Firebase Configuration

```bash
# Check Android
cat android/app/google-services.json | grep project_id

# Check iOS (if applicable)
cat ios/Runner/GoogleService-Info.plist | grep PROJECT_ID
```

## Step 5: Update App Version

Before building, update version numbers:

### 5.1 Update pubspec.yaml

```yaml
version: 1.0.0+1  # Update to your desired version
```

Format: `major.minor.patch+buildNumber`
- Example: `1.0.0+1` = Version 1.0.0, Build 1
- For updates: `1.0.1+2` = Version 1.0.1, Build 2

### 5.2 Update Android Version

Edit `android/app/build.gradle`:

```gradle
defaultConfig {
    applicationId "com.yourcompany.todoapp"
    minSdkVersion 21
    targetSdkVersion 33
    versionCode 1      // Increment for each release
    versionName "1.0.0" // Update to match pubspec.yaml
}
```

## Step 6: Build Release APK

### 6.1 Generate Signing Key (First Time Only)

```bash
# On Windows
keytool -genkey -v -keystore %USERPROFILE%\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# On macOS/Linux
keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important**: Save the keystore file and passwords securely!

### 6.2 Configure Signing

Create `android/key.properties`:

```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=upload
storeFile=C:/Users/YourName/upload-keystore.jks
```

**Security**: Add `key.properties` to `.gitignore`!

### 6.3 Update build.gradle

Edit `android/app/build.gradle`:

```gradle
// Add before android block
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // Enable code shrinking
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 6.4 Build the APK

```bash
cd todo_app_offline_sync
flutter build apk --release
```

For split APKs (smaller size):
```bash
flutter build apk --split-per-abi --release
```

This creates separate APKs for different architectures:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

### 6.5 Locate Built APK

APKs are in: `build/app/outputs/flutter-apk/`

- Universal APK: `app-release.apk` (~15-20 MB)
- Split APKs: `app-arm64-v8a-release.apk` (~10-12 MB each)

## Step 7: Test Release Build

### 7.1 Install on Physical Device

```bash
# Install universal APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or install specific architecture
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### 7.2 Test All Features

- [ ] App launches successfully
- [ ] UI renders correctly
- [ ] Can create tasks
- [ ] Can edit tasks
- [ ] Can delete tasks
- [ ] Can mark tasks complete
- [ ] Notifications work
- [ ] Google sign-in works
- [ ] Sync to cloud works
- [ ] Offline mode works
- [ ] App restarts preserve data

### 7.3 Test on Multiple Devices

Test on:
- Different Android versions (API 21+)
- Different screen sizes
- Different manufacturers (Samsung, Google, etc.)

### 7.4 Performance Testing

- [ ] App launches in < 3 seconds
- [ ] Animations are smooth (60fps)
- [ ] No lag when scrolling task list
- [ ] Sync completes in reasonable time
- [ ] Battery usage is acceptable

## Step 8: Optimize App Size

### 8.1 Check Current Size

```bash
# Check APK size
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

Target: < 15 MB for universal APK

### 8.2 Reduce Size (if needed)

**Use split APKs**:
```bash
flutter build apk --split-per-abi --release
```

**Remove unused resources**:
```bash
flutter build apk --release --target-platform android-arm64
```

**Analyze size**:
```bash
flutter build apk --analyze-size
```

### 8.3 Verify Size Reduction

Split APKs should be ~10-12 MB each (vs ~15-20 MB universal).

## Step 9: Prepare for Distribution

### 9.1 Create App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 9.2 Test App Bundle

```bash
# Install bundletool
# Download from: https://github.com/google/bundletool/releases

# Generate APKs from bundle
java -jar bundletool.jar build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=app.apks --mode=universal

# Install
java -jar bundletool.jar install-apks --apks=app.apks
```

### 9.3 Prepare Store Listing

Create:
- App icon (512x512 PNG)
- Feature graphic (1024x500 PNG)
- Screenshots (at least 2)
- App description
- Privacy policy URL

## Step 10: Environment Switching

### 10.1 Quick Environment Switch

To switch between development and production:

**For Development**:
```dart
// lib/config/app_config.dart
static const Environment environment = Environment.development;
```

**For Production**:
```dart
// lib/config/app_config.dart
static const Environment environment = Environment.production;
```

### 10.2 Build Flavors (Advanced)

For automatic environment switching, set up build flavors:

Create `lib/config/environment.dart`:
```dart
class Environment {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}
```

Build with environment:
```bash
flutter build apk --release --dart-define=API_URL=https://your-app.onrender.com/api
```

## Troubleshooting

### Build Failures

**Error**: `Gradle build failed`
- **Solution**: Update Android Gradle plugin in `android/build.gradle`
- Run: `flutter clean && flutter pub get`

**Error**: `Signing key not found`
- **Solution**: Verify `key.properties` path is correct
- Check keystore file exists at specified location

### Runtime Issues

**Error**: `CORS policy violation`
- **Solution**: Update backend `ALLOWED_ORIGINS`
- Include: `capacitor://localhost,ionic://localhost`

**Error**: `Connection timeout`
- **Solution**: Verify API URL in `app_config.dart`
- Check backend is running and accessible
- Test with: `curl https://your-app.onrender.com/health`

**Error**: `Firebase authentication failed`
- **Solution**: Verify `google-services.json` is correct
- Check Firebase project configuration
- Ensure SHA-1 fingerprint is registered in Firebase

### Performance Issues

**Issue**: App is slow
- Enable release mode optimizations
- Use `--split-per-abi` for smaller APKs
- Profile with: `flutter run --profile`

**Issue**: Large app size
- Use split APKs: `--split-per-abi`
- Remove unused assets
- Enable code shrinking in build.gradle

## Production Checklist

Before releasing:

### Configuration
- [ ] Production API URL updated in `app_config.dart`
- [ ] Environment set to `Environment.production`
- [ ] Backend CORS configured for mobile origins
- [ ] Firebase configuration verified

### Build
- [ ] Signing key generated and secured
- [ ] `key.properties` configured
- [ ] Version numbers updated
- [ ] Release APK built successfully
- [ ] APK size < 15 MB (or split APKs used)

### Testing
- [ ] Installed on physical device
- [ ] All features tested
- [ ] Authentication works
- [ ] Sync works with production backend
- [ ] Offline mode works
- [ ] Notifications work
- [ ] Performance acceptable

### Security
- [ ] Keystore file backed up securely
- [ ] `key.properties` not in version control
- [ ] API keys not hardcoded
- [ ] HTTPS used for all API calls

### Documentation
- [ ] Production URL documented
- [ ] Build instructions documented
- [ ] Known issues documented
- [ ] Support contact information added

## Monitoring Production

### User Feedback

Monitor for:
- Crash reports (see Task 16.4)
- Sync failures
- Authentication issues
- Performance complaints

### Backend Monitoring

Check backend logs for:
- API errors
- Authentication failures
- Sync conflicts
- Unusual traffic patterns

### App Updates

For updates:
1. Increment version in `pubspec.yaml`
2. Increment `versionCode` in `build.gradle`
3. Build new APK/AAB
4. Test thoroughly
5. Deploy to users

## Next Steps

After successful deployment:
- [ ] Set up crash reporting (Task 16.4)
- [ ] Monitor user feedback
- [ ] Plan feature updates
- [ ] Maintain backend infrastructure

## Support Resources

- **Flutter Documentation**: [https://docs.flutter.dev/](https://docs.flutter.dev/)
- **Android Signing**: [https://developer.android.com/studio/publish/app-signing](https://developer.android.com/studio/publish/app-signing)
- **Firebase Setup**: [https://firebase.google.com/docs/flutter/setup](https://firebase.google.com/docs/flutter/setup)
- **Play Store Publishing**: [https://developer.android.com/distribute](https://developer.android.com/distribute)
