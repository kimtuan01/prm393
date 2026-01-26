@echo off
echo ====================================
echo    FinTracker Setup Script
echo ====================================
echo.

echo [1/5] Checking Flutter installation...
flutter --version
if errorlevel 1 (
    echo ERROR: Flutter not found! Please install Flutter first.
    pause
    exit /b 1
)
echo.

echo [2/5] Getting Flutter dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies!
    pause
    exit /b 1
)
echo.

echo [3/5] Generating code with build_runner...
echo This will generate user.g.dart and transaction.g.dart files
call flutter pub run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
    echo ERROR: Failed to generate code!
    pause
    exit /b 1
)
echo.

echo [4/5] Checking Firebase configuration...
if exist "android\app\google-services.json" (
    echo ✓ google-services.json found
) else (
    echo ⚠ WARNING: google-services.json not found in android/app/
    echo Firebase features may not work!
)
echo.

echo [5/5] Setup complete!
echo.
echo ====================================
echo    Next steps:
echo ====================================
echo 1. Connect your device or start emulator
echo 2. Run: flutter run
echo 3. Login with admin@fintracker.com / Admin@123
echo.
echo ====================================

pause
