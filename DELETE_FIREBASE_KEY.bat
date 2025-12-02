@echo off
echo ========================================
echo Delete Firebase Service Account Key
echo ========================================
echo.
echo This will delete:
echo backend\todolist-409ad-firebase-adminsdk-fbsvc-a6384e4726.json
echo.
echo This file contains your Firebase private key and should
echo NEVER be committed to GitHub!
echo.
pause

if exist "backend\todolist-409ad-firebase-adminsdk-fbsvc-a6384e4726.json" (
    del "backend\todolist-409ad-firebase-adminsdk-fbsvc-a6384e4726.json"
    echo.
    echo [OK] File deleted successfully!
    echo.
    echo IMPORTANT: You'll need to download a new service account key
    echo from Firebase Console when deploying to production.
    echo.
    echo Store it securely and use environment variables, never commit it!
    echo.
) else (
    echo.
    echo [OK] File not found - already deleted or doesn't exist.
    echo.
)

echo Next step: Run verify-github-ready.bat to check if you're ready to push.
echo.
pause
