# Release Build Checklist

Use this checklist before building and releasing the Todo App.

## Pre-Build Checklist

### Code Preparation
- [ ] All features implemented and tested
- [ ] All tests passing: `flutter test`
- [ ] No debug code or console logs in production code
- [ ] Error handling implemented for all critical paths
- [ ] Performance optimizations applied

### Configuration
- [ ] Production API URL updated in `lib/config/app_config.dart`
- [ ] Environment set to `Environment.production`
- [ ] Firebase configuration files present:
  - [ ] `android/app/google-services.json`
  - [ ] `ios/Runner/GoogleService-Info.plist` (if building for iOS)
- [ ] App version updated in `pubspec.yaml`
- [ ] Version code incremented in `android/app/build.gradle.kts`

### Backend Verification
- [ ] Backend deployed and accessible
- [ ] Health endpoint working: `curl https://your-api.com/health`
- [ ] CORS configured for mobile origins
- [ ] MongoDB Atlas connected
- [ ] Firebase authentication working

### Signing Setup
- [ ] Keystore generated (see `android/SIGNING_SETUP.md`)
- [ ] `android/key.properties` created and configured
- [ ] Keystore backed up securely
- [ ] Passwords saved in password manager
- [ ] `key.properties` in `.gitignore`
- [ ] Keystore file NOT in repository

## Build Process

### Clean Build
```bash
flutter clean
flutter pub get
```

### Build Options

Choose one:

#### Option 1: Split APKs (Recommended - Smaller Size)
```bash
flutter build apk --split-per-abi --release
```
Creates:
- `app-armeabi-v7a-release.apk` (~10 MB)
- `app-arm64-v8a-release.apk` (~12 MB)
- `app-x86_64-release.apk` (~12 MB)

#### Option 2: Universal APK
```bash
flutter build apk --release
```
Creates:
- `app-release.apk` (~15-20 MB)

#### Option 3: App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Creates:
- `app-release.aab` (~15 MB)

### Build Verification
- [ ] Build completed without errors
- [ ] APK/AAB files created in `build/app/outputs/`
- [ ] File sizes are reasonable (< 15 MB for universal APK)
- [ ] No warnings about missing signing configuration

## Testing Release Build

### Installation
```bash
# Install on connected device
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Functional Testing
- [ ] App installs successfully
- [ ] App launches without crashes
- [ ] No debug banner visible
- [ ] Splash screen displays correctly
- [ ] All screens render properly

### Feature Testing
- [ ] Create task works
- [ ] Edit task works
- [ ] Delete task works
- [ ] Mark task complete works
- [ ] Task list displays correctly
- [ ] Task sorting works (priority, due date)
- [ ] Notifications schedule correctly
- [ ] Notification tap opens correct task

### Authentication Testing
- [ ] Google sign-in works
- [ ] Sign-out works
- [ ] Token persists across app restarts
- [ ] Authentication errors handled gracefully

### Sync Testing
- [ ] Sync to cloud works
- [ ] Sync from cloud works
- [ ] Conflict resolution works
- [ ] Offline queue works
- [ ] Sync errors handled gracefully

### Offline Testing
- [ ] Enable airplane mode
- [ ] Create tasks offline
- [ ] Edit tasks offline
- [ ] Delete tasks offline
- [ ] Mark tasks complete offline
- [ ] Disable airplane mode
- [ ] Sync completes successfully
- [ ] All offline changes synced

### Performance Testing
- [ ] App launches in < 3 seconds
- [ ] Animations are smooth (60fps)
- [ ] No lag when scrolling
- [ ] Task list loads quickly
- [ ] Sync completes in reasonable time
- [ ] Battery usage is acceptable
- [ ] Memory usage is reasonable

### UI/UX Testing
- [ ] All text is readable
- [ ] Colors and contrast are good
- [ ] Touch targets are adequate size
- [ ] Animations are smooth
- [ ] Loading states display correctly
- [ ] Error messages are clear
- [ ] Empty states display correctly

### Device Testing
Test on multiple devices:
- [ ] Different Android versions (API 21+)
- [ ] Different screen sizes (small, medium, large)
- [ ] Different manufacturers (Samsung, Google, etc.)
- [ ] Different screen densities

## Security Verification

### Code Security
- [ ] No hardcoded API keys
- [ ] No hardcoded passwords
- [ ] No sensitive data in logs
- [ ] HTTPS used for all API calls
- [ ] Input validation implemented
- [ ] SQL injection prevention (parameterized queries)

### Build Security
- [ ] Keystore secured
- [ ] `key.properties` not in repository
- [ ] ProGuard rules applied
- [ ] Code obfuscation enabled
- [ ] Debug symbols removed

### Runtime Security
- [ ] Firebase token validation works
- [ ] Authentication required for protected features
- [ ] Local data encrypted (if applicable)
- [ ] Network security config applied

## App Store Preparation (Optional)

### Google Play Store

#### Assets Required
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Screenshots (at least 2, up to 8)
  - [ ] Phone screenshots (16:9 or 9:16)
  - [ ] Tablet screenshots (optional)
- [ ] Short description (80 characters max)
- [ ] Full description (4000 characters max)
- [ ] Privacy policy URL

#### Store Listing
- [ ] App title chosen
- [ ] Category selected
- [ ] Content rating completed
- [ ] Target audience defined
- [ ] Privacy policy created and hosted

#### Technical Setup
- [ ] App bundle uploaded
- [ ] Release notes written
- [ ] Pricing set (free)
- [ ] Countries selected
- [ ] Internal testing track created (optional)

## Post-Build Tasks

### Documentation
- [ ] Release notes written
- [ ] Version number documented
- [ ] Build date recorded
- [ ] Known issues documented
- [ ] Changelog updated

### Distribution
- [ ] APK uploaded to distribution platform
- [ ] Download link shared with testers
- [ ] Installation instructions provided
- [ ] Feedback mechanism established

### Monitoring Setup
- [ ] Crash reporting configured (see Task 16.4)
- [ ] Analytics configured (optional)
- [ ] Error tracking enabled
- [ ] Performance monitoring enabled

## Rollback Plan

In case of critical issues:

### Immediate Actions
- [ ] Remove download links
- [ ] Notify users of issue
- [ ] Identify root cause
- [ ] Prepare hotfix

### Rollback Steps
- [ ] Revert to previous version
- [ ] Rebuild with fix
- [ ] Test thoroughly
- [ ] Redeploy

## Version Management

### Version Numbering
Format: `major.minor.patch+buildNumber`

Example: `1.0.0+1`
- Major: Breaking changes
- Minor: New features
- Patch: Bug fixes
- Build: Incremental build number

### Update Process
1. Update `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2
   ```

2. Update `android/app/build.gradle.kts`:
   ```kotlin
   versionCode = 2
   versionName = "1.0.1"
   ```

3. Commit version changes
4. Tag release: `git tag v1.0.1`
5. Build and test
6. Deploy

## Common Issues and Solutions

### Build Fails

**Issue**: Gradle build fails
- **Solution**: Run `flutter clean && flutter pub get`
- Check `build.gradle.kts` syntax
- Update Gradle version if needed

**Issue**: Signing fails
- **Solution**: Verify `key.properties` paths
- Check keystore file exists
- Verify passwords are correct

### Runtime Issues

**Issue**: App crashes on launch
- **Solution**: Check ProGuard rules
- Add keep rules for crashing classes
- Test with `--no-shrink` flag

**Issue**: API calls fail
- **Solution**: Verify production URL
- Check CORS configuration
- Test backend health endpoint

**Issue**: Authentication fails
- **Solution**: Verify Firebase configuration
- Check `google-services.json`
- Verify SHA-1 fingerprint in Firebase

### Performance Issues

**Issue**: App is slow
- **Solution**: Profile with `flutter run --profile`
- Optimize heavy operations
- Reduce widget rebuilds

**Issue**: Large app size
- **Solution**: Use split APKs
- Remove unused assets
- Enable code shrinking

## Final Checklist

Before releasing to users:

- [ ] All tests passed
- [ ] Release build tested on multiple devices
- [ ] All features working correctly
- [ ] Performance is acceptable
- [ ] Security verified
- [ ] Documentation updated
- [ ] Backup created
- [ ] Rollback plan ready
- [ ] Support channels prepared
- [ ] Monitoring configured

## Release Notes Template

```
Version 1.0.0 (Build 1)
Release Date: YYYY-MM-DD

New Features:
- Feature 1
- Feature 2

Improvements:
- Improvement 1
- Improvement 2

Bug Fixes:
- Fix 1
- Fix 2

Known Issues:
- Issue 1 (workaround: ...)

Technical Details:
- Minimum Android version: 5.0 (API 21)
- Target Android version: 13 (API 33)
- App size: ~12 MB (arm64-v8a)
```

## Support Resources

- **Flutter Build**: [https://docs.flutter.dev/deployment/android](https://docs.flutter.dev/deployment/android)
- **Android Signing**: [https://developer.android.com/studio/publish/app-signing](https://developer.android.com/studio/publish/app-signing)
- **Play Console**: [https://play.google.com/console](https://play.google.com/console)
- **Firebase**: [https://console.firebase.google.com/](https://console.firebase.google.com/)

## Notes

Add any release-specific notes here:

```
Build Date: _______________
Built By: _______________
Version: _______________
Build Number: _______________
Backend URL: _______________
Firebase Project: _______________
Known Issues: _______________
```
