# Todo App - Offline Sync

A Flutter-based to-do list application with offline-first architecture and optional cloud synchronization.

## Features

- ✅ Create, edit, and delete tasks
- 📅 Set priority levels (1-5) and due dates
- 🔔 Local push notifications for task reminders
- 📱 Offline-first - works without internet
- ☁️ Optional cloud sync with Google authentication
- 🎨 Beautiful Material Design 3 UI with smooth animations
- 🔄 Automatic conflict resolution for multi-device sync
- 💾 SQLite local storage for data persistence

## Getting Started

### Prerequisites

- Flutter SDK 3.x or later
- Android Studio or VS Code with Flutter extensions
- Firebase project (for authentication)
- Backend API deployed (see backend/DEPLOYMENT_GUIDE.md)

### Installation

1. Clone the repository
2. Install dependencies:
```bash
cd todo_app_offline_sync
flutter pub get
```

3. Configure Firebase:
   - Add `google-services.json` to `android/app/`
   - See `FIREBASE_SETUP.md` for detailed instructions

4. Configure API endpoint:
   - Edit `lib/config/app_config.dart`
   - Set environment and production URL

5. Run the app:
```bash
flutter run
```

## Configuration

### Environment Setup

The app supports two environments: development and production.

**Quick Reference**: See [ENVIRONMENT_SETUP.md](./ENVIRONMENT_SETUP.md)

**Development** (default):
- API: `http://localhost:3000/api`
- Requires local backend running

**Production**:
- API: Your deployed backend URL
- Requires backend deployed to Render/Railway/Fly.io

To switch environments, edit `lib/config/app_config.dart`:

```dart
static const Environment environment = Environment.production; // or development
```

### Update Production URL

After deploying your backend:

1. Get your production URL (e.g., `https://your-app.onrender.com`)
2. Update `lib/config/app_config.dart`:

```dart
case Environment.production:
  return 'https://your-app.onrender.com/api'; // Update this!
```

## Building for Production

### Build Release APK

```bash
# Universal APK
flutter build apk --release

# Split APKs (smaller size, recommended)
flutter build apk --split-per-abi --release
```

**Detailed Guide**: See [PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md)

### Build App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

## Testing

### Run All Tests

```bash
flutter test
```

### Run Specific Test Suites

```bash
# Unit tests
flutter test test/models/
flutter test test/services/

# Property-based tests
flutter test test/properties/

# Integration tests
flutter test integration_test/
```

### Run Performance Tests

```bash
flutter test test/performance_test.dart
```

## Project Structure

```
lib/
├── blocs/              # BLoC state management
├── config/             # App configuration
├── models/             # Data models
├── repositories/       # Data access layer
├── screens/            # UI screens
├── services/           # Business logic services
├── utils/              # Utility functions
└── widgets/            # Reusable widgets

test/
├── blocs/              # BLoC tests
├── models/             # Model tests
├── properties/         # Property-based tests
└── services/           # Service tests
```

## Architecture

The app follows a clean architecture pattern:

- **Presentation Layer**: Flutter widgets and screens
- **Business Logic Layer**: BLoC pattern for state management
- **Data Layer**: Repositories and services
- **Local Storage**: SQLite database
- **Cloud Sync**: REST API with Firebase authentication

## Deployment Guides

- **[PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md)** - Complete Flutter app deployment guide
- **[ENVIRONMENT_SETUP.md](./ENVIRONMENT_SETUP.md)** - Environment configuration reference
- **[FIREBASE_SETUP.md](./FIREBASE_SETUP.md)** - Firebase configuration guide
- **[../backend/DEPLOYMENT_GUIDE.md](../backend/DEPLOYMENT_GUIDE.md)** - Backend deployment guide

## Key Technologies

- **Flutter**: Cross-platform mobile framework
- **BLoC**: State management pattern
- **SQLite**: Local database (sqflite)
- **Firebase**: Authentication (Google OAuth)
- **Dio**: HTTP client for API calls
- **flutter_local_notifications**: Push notifications

## Performance

- App size: < 15 MB (with split APKs: ~10-12 MB)
- Target: 60fps animations
- Offline-first: All operations work without internet
- Efficient sync: Only changed data transmitted

## Security

- HTTPS for all API communication
- Firebase token-based authentication
- Secure local storage
- No sensitive data in logs
- CORS protection on backend

## Troubleshooting

### Common Issues

**CORS Errors**:
- Update backend `ALLOWED_ORIGINS` to include `capacitor://localhost`

**Connection Timeout**:
- Verify API URL in `app_config.dart`
- Check backend is running and accessible
- Test: `curl https://your-api.com/health`

**Build Failures**:
- Run: `flutter clean && flutter pub get`
- Update Flutter: `flutter upgrade`

**Authentication Issues**:
- Verify `google-services.json` is correct
- Check Firebase project configuration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `flutter test`
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Check deployment guides in this directory
- Review backend documentation in `../backend/`
- Consult Flutter documentation: [https://docs.flutter.dev/](https://docs.flutter.dev/)

## Next Steps

After setup:
1. Deploy backend (see `../backend/DEPLOYMENT_GUIDE.md`)
2. Update production URL in `app_config.dart`
3. Build release APK
4. Test on physical device
5. Set up crash reporting (Firebase Crashlytics)

## Acknowledgments

Built with Flutter and Firebase for offline-first task management.
