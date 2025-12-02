@echo off
REM Build script for Windows
REM This script builds release APKs for the Todo App

echo ========================================
echo Todo App - Release Build Script
echo ========================================
echo.

REM Check if key.properties exists
if not exist "android\key.properties" (
    echo ERROR: android\key.properties not found!
    echo.
    echo Please create your signing key first:
    echo 1. See android\SIGNING_SETUP.md for instructions
    echo 2. Generate keystore: keytool -genkey -v -keystore %%USERPROFILE%%\upload-keystore.jks ...
    echo 3. Create android\key.properties from android\key.properties.example
    echo.
    pause
    exit /b 1
)

echo [1/4] Cleaning previous builds...
call flutter clean
if errorlevel 1 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)

echo.
echo [2/4] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b 1
)

echo.
echo [3/4] Building release APKs (split by ABI)...
echo This will create separate APKs for different architectures.
echo.
call flutter build apk --split-per-abi --release
if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo [4/4] Build complete!
echo.
echo ========================================
echo APKs created in: build\app\outputs\flutter-apk\
echo.
dir /B build\app\outputs\flutter-apk\*.apk
echo.
echo ========================================
echo.
echo To install on device:
echo   adb install build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo.
echo To build universal APK instead:
echo   flutter build apk --release
echo.
pause
