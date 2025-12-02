@echo off
REM Performance and size testing script
echo ========================================
echo Todo App Performance Testing
echo ========================================
echo.

REM Check if Flutter is available
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter is not installed or not in PATH
    pause
    exit /b 1
)

echo [1/5] Running Flutter analyze...
flutter analyze
if errorlevel 1 (
    echo WARNING: Flutter analyze found issues
) else (
    echo ✓ No analysis issues found
)
echo.

echo [2/5] Building release APK with size analysis...
flutter build apk --release --split-per-abi --analyze-size
if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)
echo.

echo [3/5] Checking APK sizes...
echo.
echo APK files in build\app\outputs\flutter-apk\:
dir /B build\app\outputs\flutter-apk\*.apk
echo.

REM Check individual APK sizes
for %%f in (build\app\outputs\flutter-apk\*.apk) do (
    echo Checking size of %%~nxf...
    for %%s in (%%f) do (
        set size=%%~zs
        set /a sizeMB=%%~zs/1048576
        echo   Size: !sizeMB! MB
        if !sizeMB! GTR 15 (
            echo   WARNING: APK size exceeds 15MB target
        ) else (
            echo   ✓ APK size is within target
        )
    )
    echo.
)

echo [4/5] Running unit tests...
flutter test
if errorlevel 1 (
    echo WARNING: Some tests failed
) else (
    echo ✓ All tests passed
)
echo.

echo [5/5] Performance recommendations:
echo.
echo To test on a physical device:
echo   1. Connect your Android device
echo   2. Run: flutter run --release
echo   3. Monitor performance using DevTools
echo.
echo To profile performance:
echo   flutter run --profile
echo   flutter run --profile --trace-skia
echo.
echo To check for jank:
echo   Open DevTools and check the Performance tab
echo   Look for frames taking more than 16ms (60fps)
echo.
echo ========================================
echo Performance Testing Complete
echo ========================================
pause
