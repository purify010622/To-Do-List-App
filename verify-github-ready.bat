@echo off
echo ========================================
echo GitHub Ready Verification Script
echo ========================================
echo.

echo [1/5] Checking for Firebase service account key...
if exist "backend\todolist-409ad-firebase-adminsdk-fbsvc-a6384e4726.json" (
    echo [X] CRITICAL: Firebase key file still exists!
    echo     Delete it with: del backend\todolist-409ad-firebase-adminsdk-fbsvc-a6384e4726.json
    set FIREBASE_KEY_EXISTS=1
) else (
    echo [OK] Firebase key file not found
    set FIREBASE_KEY_EXISTS=0
)
echo.

echo [2/5] Checking for .env files...
if exist "backend\.env" (
    echo [!] WARNING: backend\.env exists (make sure it's in .gitignore)
) else (
    echo [OK] No .env file found
)
echo.

echo [3/5] Checking for Android signing keys...
dir /s /b *.jks *.keystore 2>nul
if errorlevel 1 (
    echo [OK] No signing keys found
) else (
    echo [!] WARNING: Signing keys found (make sure they're in .gitignore)
)
echo.

echo [4/5] Checking .gitignore files...
if exist ".gitignore" (
    echo [OK] Root .gitignore exists
) else (
    echo [X] Root .gitignore missing!
)
if exist "backend\.gitignore" (
    echo [OK] Backend .gitignore exists
) else (
    echo [X] Backend .gitignore missing!
)
if exist "todo_app_offline_sync\.gitignore" (
    echo [OK] Flutter .gitignore exists
) else (
    echo [X] Flutter .gitignore missing!
)
echo.

echo [5/5] Checking documentation...
if exist "README.md" (echo [OK] README.md) else (echo [X] README.md missing)
if exist "SECURITY.md" (echo [OK] SECURITY.md) else (echo [X] SECURITY.md missing)
if exist "LICENSE" (echo [OK] LICENSE) else (echo [X] LICENSE missing)
echo.

echo ========================================
echo Summary
echo ========================================
if %FIREBASE_KEY_EXISTS%==1 (
    echo.
    echo [X] NOT READY FOR GITHUB
    echo.
    echo CRITICAL: Delete the Firebase service account key file first!
    echo Run: del backend\todolist-409ad-firebase-adminsdk-fbsvc-a6384e4726.json
    echo.
) else (
    echo.
    echo [OK] Project appears ready for GitHub!
    echo.
    echo Next steps:
    echo 1. Review: git status
    echo 2. Add files: git add .
    echo 3. Commit: git commit -m "Initial commit"
    echo 4. Push: git push -u origin main
    echo.
    echo Read BEFORE_GITHUB_PUSH.md for complete instructions.
    echo.
)

pause
