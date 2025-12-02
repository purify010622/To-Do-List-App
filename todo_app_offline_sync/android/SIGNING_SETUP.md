# Android App Signing Setup Guide

This guide explains how to generate a signing key and configure your Android app for release builds.

## Why App Signing is Required

Android requires all apps to be digitally signed before installation. For release builds (production), you need your own signing key.

## Step 1: Generate Signing Key

### On Windows

Open Command Prompt or PowerShell and run:

```cmd
keytool -genkey -v -keystore %USERPROFILE%\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### On macOS/Linux

Open Terminal and run:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Fill in the Information

You'll be prompted for:

1. **Keystore password**: Create a strong password (save this!)
2. **Key password**: Create another strong password (save this!)
3. **First and last name**: Your name or company name
4. **Organizational unit**: Your department (e.g., "Development")
5. **Organization**: Your company name
6. **City/Locality**: Your city
7. **State/Province**: Your state
8. **Country code**: Two-letter country code (e.g., "US")

**Example**:
```
Enter keystore password: MySecurePassword123!
Re-enter new password: MySecurePassword123!
What is your first and last name?
  [Unknown]:  John Doe
What is the name of your organizational unit?
  [Unknown]:  Development
What is the name of your organization?
  [Unknown]:  TodoApp Inc
What is the name of your City or Locality?
  [Unknown]:  San Francisco
What is the name of your State or Province?
  [Unknown]:  California
What is the two-letter country code for this unit?
  [Unknown]:  US
Is CN=John Doe, OU=Development, O=TodoApp Inc, L=San Francisco, ST=California, C=US correct?
  [no]:  yes

Enter key password for <upload>
        (RETURN if same as keystore password): MyKeyPassword123!
Re-enter new password: MyKeyPassword123!
```

### Verify Key Creation

**Windows**:
```cmd
dir %USERPROFILE%\upload-keystore.jks
```

**macOS/Linux**:
```bash
ls -l ~/upload-keystore.jks
```

You should see the keystore file (~2-3 KB).

## Step 2: Secure Your Keystore

### Important Security Notes

⚠️ **CRITICAL**: 
- **Never commit the keystore file to version control**
- **Never share the keystore passwords**
- **Back up the keystore file securely**
- **If you lose the keystore, you cannot update your app on Play Store**

### Backup Keystore

1. Copy `upload-keystore.jks` to a secure location:
   - External hard drive
   - Encrypted cloud storage (Google Drive, Dropbox)
   - Password manager (as attachment)

2. Save passwords securely:
   - Use a password manager (recommended)
   - Store in encrypted document
   - Never in plain text files

### Recommended Backup Locations

- **Password Manager**: 1Password, LastPass, Bitwarden
- **Cloud Storage**: Google Drive (in encrypted folder)
- **Physical**: USB drive in safe location

## Step 3: Configure Android Build

### Create key.properties File

Create `android/key.properties` with your keystore information:

**Windows** (adjust path to your username):
```properties
storePassword=MySecurePassword123!
keyPassword=MyKeyPassword123!
keyAlias=upload
storeFile=C:/Users/YourUsername/upload-keystore.jks
```

**macOS/Linux**:
```properties
storePassword=MySecurePassword123!
keyPassword=MyKeyPassword123!
keyAlias=upload
storeFile=/Users/yourusername/upload-keystore.jks
```

**Important**: Replace with your actual:
- Passwords (from Step 1)
- Username in the file path
- Use forward slashes `/` even on Windows

### Verify key.properties

Check the file exists:
```bash
cat android/key.properties
```

### Add to .gitignore

Ensure `android/key.properties` is in `.gitignore`:

```bash
# Check if already ignored
grep "key.properties" .gitignore

# If not, add it
echo "android/key.properties" >> .gitignore
```

## Step 4: Update build.gradle.kts

The build configuration is already set up in `android/app/build.gradle.kts`, but you need to add the signing configuration.

### Add Signing Configuration

Edit `android/app/build.gradle.kts` and add this code **before** the `android {` block:

```kotlin
// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}
```

### Add Signing Config

Inside the `android {` block, add the `signingConfigs` section **before** `buildTypes`:

```kotlin
android {
    // ... existing config

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            
            // Enable code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // ... rest of config
}
```

## Step 5: Create ProGuard Rules

Create `android/app/proguard-rules.pro` to prevent issues with code shrinking:

```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Keep model classes
-keep class com.todoapp.todo_app_offline_sync.** { *; }
```

## Step 6: Test Signing Configuration

### Build Release APK

```bash
cd todo_app_offline_sync
flutter build apk --release
```

### Expected Output

```
Running Gradle task 'assembleRelease'...
✓ Built build/app/outputs/flutter-apk/app-release.apk (15.2MB)
```

### Verify Signing

Check the APK is signed:

```bash
# Windows (requires Android SDK)
"%ANDROID_HOME%\build-tools\33.0.0\apksigner.bat" verify build/app/outputs/flutter-apk/app-release.apk

# macOS/Linux
$ANDROID_HOME/build-tools/33.0.0/apksigner verify build/app/outputs/flutter-apk/app-release.apk
```

Expected output:
```
Verifies
Verified using v1 scheme (JAR signing): true
Verified using v2 scheme (APK Signature Scheme v2): true
```

## Step 7: Build Split APKs (Recommended)

For smaller app sizes, build split APKs:

```bash
flutter build apk --split-per-abi --release
```

This creates separate APKs for different architectures:
- `app-armeabi-v7a-release.apk` (~10 MB) - 32-bit ARM
- `app-arm64-v8a-release.apk` (~12 MB) - 64-bit ARM (most common)
- `app-x86_64-release.apk` (~12 MB) - 64-bit x86 (emulators)

## Step 8: Install and Test

### Install on Device

```bash
# Install universal APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or install specific architecture
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Test the App

- [ ] App installs successfully
- [ ] App launches without crashes
- [ ] All features work correctly
- [ ] No debug banners or logs
- [ ] Performance is good

## Troubleshooting

### Error: "keytool: command not found"

**Solution**: Install Java JDK
- Download from: [https://www.oracle.com/java/technologies/downloads/](https://www.oracle.com/java/technologies/downloads/)
- Or use OpenJDK: [https://adoptium.net/](https://adoptium.net/)

### Error: "keystore file does not exist"

**Solution**: Check the path in `key.properties`
- Use absolute path
- Use forward slashes `/` even on Windows
- Verify file exists at that location

### Error: "Keystore was tampered with, or password was incorrect"

**Solution**: Verify passwords in `key.properties`
- Check for typos
- Ensure no extra spaces
- Passwords are case-sensitive

### Error: "Failed to read key from keystore"

**Solution**: Verify key alias
- Default alias is `upload`
- Check with: `keytool -list -v -keystore upload-keystore.jks`

### Build Fails with ProGuard Errors

**Solution**: Update `proguard-rules.pro`
- Add keep rules for classes causing issues
- Check error messages for class names
- Add: `-keep class com.example.ClassName { *; }`

## Security Checklist

Before committing code:

- [ ] Keystore file NOT in repository
- [ ] `key.properties` NOT in repository
- [ ] `key.properties` in `.gitignore`
- [ ] Keystore backed up securely
- [ ] Passwords saved in password manager
- [ ] No passwords in code or comments

## Play Store Preparation

### Generate App Bundle

For Play Store submission, use App Bundle instead of APK:

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Register Signing Key

1. Go to [Google Play Console](https://play.google.com/console)
2. Create app
3. Go to "Release" → "Setup" → "App signing"
4. Upload your signing key or use Play App Signing

### Get SHA-1 Fingerprint

For Firebase configuration:

```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload
```

Copy the SHA-1 fingerprint and add to Firebase console.

## Key Management Best Practices

1. **Use Different Keys**:
   - Development: Debug key (auto-generated)
   - Production: Release key (your keystore)

2. **Rotate Keys Periodically**:
   - Every 2-3 years
   - After security incidents
   - When team members leave

3. **Access Control**:
   - Limit who has access to keystore
   - Use CI/CD for automated builds
   - Store in secure CI/CD secrets

4. **Documentation**:
   - Document keystore location
   - Record creation date
   - Note expiration date (10,000 days from creation)

## CI/CD Integration

For automated builds:

### GitHub Actions Example

```yaml
- name: Decode keystore
  run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks

- name: Create key.properties
  run: |
    echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
    echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
    echo "keyAlias=upload" >> android/key.properties
    echo "storeFile=upload-keystore.jks" >> android/key.properties

- name: Build APK
  run: flutter build apk --release
```

## Support Resources

- **Android Signing**: [https://developer.android.com/studio/publish/app-signing](https://developer.android.com/studio/publish/app-signing)
- **Flutter Build**: [https://docs.flutter.dev/deployment/android](https://docs.flutter.dev/deployment/android)
- **Play Console**: [https://support.google.com/googleplay/android-developer](https://support.google.com/googleplay/android-developer)

## Quick Reference

### Generate Key
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Build Release APK
```bash
flutter build apk --release
```

### Build Split APKs
```bash
flutter build apk --split-per-abi --release
```

### Build App Bundle
```bash
flutter build appbundle --release
```

### Verify Signing
```bash
apksigner verify app-release.apk
```

### List Keystore Info
```bash
keytool -list -v -keystore upload-keystore.jks
```
