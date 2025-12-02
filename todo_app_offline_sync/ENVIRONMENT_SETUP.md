# Environment Configuration Quick Reference

This guide explains how to switch between development and production environments.

## Quick Switch

### Switch to Development

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const Environment environment = Environment.development;
  // ...
}
```

Then run:
```bash
flutter run
```

API will connect to: `http://localhost:3000/api`

### Switch to Production

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const Environment environment = Environment.production;
  // ...
}
```

Then build:
```bash
flutter build apk --release
```

API will connect to: Your production URL (e.g., `https://your-app.onrender.com/api`)

## Environment Comparison

| Feature | Development | Production |
|---------|-------------|------------|
| API URL | `http://localhost:3000/api` | `https://your-app.onrender.com/api` |
| Debug Logging | Enabled | Disabled |
| Backend | Local server | Deployed server |
| Database | Local MongoDB or Atlas | MongoDB Atlas |
| Build Type | Debug | Release |
| Code Optimization | Minimal | Full |
| App Size | Larger | Optimized |

## Configuration File Location

**File**: `lib/config/app_config.dart`

```dart
class AppConfig {
  /// Change this to switch environments
  static const Environment environment = Environment.development; // or Environment.production

  /// API base URL based on environment
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://localhost:3000/api';
      case Environment.production:
        return 'https://your-app.onrender.com/api'; // Update this!
    }
  }

  /// Debug logging enabled in development only
  static bool get enableDebugLogging {
    return environment == Environment.development;
  }

  // ... other configuration
}
```

## Update Production URL

After deploying your backend, update the production URL:

1. Deploy backend (see `backend/DEPLOYMENT_GUIDE.md`)
2. Get your production URL (e.g., from Render dashboard)
3. Update `app_config.dart`:

```dart
case Environment.production:
  return 'https://todo-app-backend.onrender.com/api'; // Your actual URL
```

## Testing Environments

### Test Development Environment

```bash
# 1. Ensure backend is running locally
cd backend
npm run dev

# 2. Set environment to development in app_config.dart
# 3. Run app
cd ../todo_app_offline_sync
flutter run
```

### Test Production Environment

```bash
# 1. Ensure backend is deployed and accessible
curl https://your-app.onrender.com/health

# 2. Set environment to production in app_config.dart
# 3. Build and install
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Common Issues

### Wrong Environment

**Symptom**: App can't connect to API

**Check**:
1. Verify environment setting in `app_config.dart`
2. Check API URL matches your backend
3. For development: Ensure local backend is running
4. For production: Ensure deployed backend is accessible

### CORS Errors

**Symptom**: "CORS policy violation" errors

**Solution**:
- Development: Backend should allow `http://localhost`
- Production: Backend should allow `capacitor://localhost` and `ionic://localhost`

Update backend `ALLOWED_ORIGINS` environment variable.

### Connection Timeout

**Symptom**: Requests timeout

**Check**:
1. Backend is running and accessible
2. API URL is correct (including `/api` suffix)
3. Network connectivity
4. Firewall settings

## Environment Variables Checklist

### Development
- [ ] `environment = Environment.development`
- [ ] Local backend running on port 3000
- [ ] MongoDB accessible (local or Atlas)
- [ ] Firebase configured

### Production
- [ ] `environment = Environment.production`
- [ ] Production URL updated in `app_config.dart`
- [ ] Backend deployed and accessible
- [ ] MongoDB Atlas configured
- [ ] Firebase configured
- [ ] Backend CORS allows mobile origins

## Build Commands Reference

### Development Builds

```bash
# Debug build (for testing)
flutter run

# Debug APK
flutter build apk --debug
```

### Production Builds

```bash
# Release APK (universal)
flutter build apk --release

# Release APK (split by architecture - smaller size)
flutter build apk --split-per-abi --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

## Advanced: Build Flavors

For automatic environment switching without code changes:

### Setup (Optional)

1. Create environment-specific entry points:
   - `lib/main_dev.dart`
   - `lib/main_prod.dart`

2. Use dart-define for configuration:
```bash
# Development
flutter run --dart-define=ENVIRONMENT=development

# Production
flutter build apk --release --dart-define=ENVIRONMENT=production
```

3. Read in code:
```dart
const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
```

## Best Practices

1. **Never commit production credentials** to version control
2. **Test in development** before building for production
3. **Verify API URL** before each production build
4. **Keep environments separate** - don't mix dev and prod data
5. **Document your production URL** for team members

## Quick Checklist

Before switching environments:

### To Development
- [ ] Set `Environment.development` in `app_config.dart`
- [ ] Start local backend: `npm run dev`
- [ ] Run app: `flutter run`

### To Production
- [ ] Set `Environment.production` in `app_config.dart`
- [ ] Update production URL if changed
- [ ] Verify backend is accessible
- [ ] Build release: `flutter build apk --release`
- [ ] Test on device

## Support

If you encounter issues:
1. Check environment setting in `app_config.dart`
2. Verify backend is running/accessible
3. Check API URL format (include `/api`)
4. Review backend logs for errors
5. Test health endpoint: `curl https://your-api.com/health`
