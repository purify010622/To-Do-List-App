# Firebase Setup Instructions

This document provides instructions for setting up Firebase for the TodoApp.

## Prerequisites

- A Google account
- Flutter CLI installed
- FlutterFire CLI installed (`dart pub global activate flutterfire_cli`)

## Steps

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard to create your project
4. Enable Google Analytics (optional)

### 2. Enable Authentication

1. In the Firebase Console, navigate to **Authentication**
2. Click "Get started"
3. Go to the **Sign-in method** tab
4. Enable **Google** as a sign-in provider
5. Add your support email

### 3. Register Your Android App

1. In the Firebase Console, click the Android icon to add an Android app
2. Enter the package name: `com.todoapp.todo_app_offline_sync`
3. Enter an app nickname (optional): "TodoApp Android"
4. Enter SHA-1 certificate (for Google Sign-In):
   - For debug: Run `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
   - Copy the SHA-1 fingerprint
5. Click "Register app"
6. Download the `google-services.json` file
7. Place `google-services.json` in `android/app/` directory

### 4. Configure FlutterFire (Alternative Method)

Alternatively, you can use the FlutterFire CLI to automatically configure Firebase:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure
```

This will:
- Create a Firebase project (or select existing)
- Register your app with Firebase
- Download configuration files
- Generate `lib/firebase_options.dart`

### 5. Update Android Build Configuration

The `google-services.json` file should be placed in:
```
android/app/google-services.json
```

Ensure your `android/build.gradle` includes:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

And your `android/app/build.gradle` includes:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 6. Initialize Firebase in Your App

Firebase will be initialized in `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### 7. Set Up Cloud Firestore or Realtime Database (Optional)

If you plan to use Firestore for additional features:

1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Choose "Start in test mode" for development
4. Select a location for your database

### 8. Verify Setup

Run your app to verify Firebase is properly configured:

```bash
flutter run
```

Check the console for any Firebase initialization errors.

## Troubleshooting

### Google Sign-In Issues

- Ensure SHA-1 certificate is added to Firebase Console
- Verify package name matches exactly: `com.todoapp.todo_app_offline_sync`
- Check that Google Sign-In is enabled in Firebase Authentication

### google-services.json Not Found

- Ensure the file is in `android/app/google-services.json`
- Run `flutter clean` and rebuild

### Build Errors

- Update Android Gradle Plugin to latest version
- Ensure minimum SDK version is 21 or higher in `android/app/build.gradle`

## Security Notes

- **Never commit `google-services.json` to public repositories**
- Add `google-services.json` to `.gitignore` if needed
- Use Firebase Security Rules to protect your data
- Implement proper authentication checks in your backend

## Next Steps

After completing Firebase setup:
1. Test authentication flow
2. Configure backend API with Firebase Admin SDK
3. Set up security rules for production
4. Enable Firebase Crashlytics for error tracking
