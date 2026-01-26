#!/bin/bash

echo "===================================="
echo "   FinTracker Setup Script"
echo "===================================="
echo ""

echo "[1/5] Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter not found! Please install Flutter first."
    exit 1
fi
flutter --version
echo ""

echo "[2/5] Getting Flutter dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get dependencies!"
    exit 1
fi
echo ""

echo "[3/5] Generating code with build_runner..."
echo "This will generate user.g.dart and transaction.g.dart files"
flutter pub run build_runner build --delete-conflicting-outputs
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to generate code!"
    exit 1
fi
echo ""

echo "[4/5] Checking Firebase configuration..."
if [ -f "android/app/google-services.json" ]; then
    echo "✓ google-services.json found"
else
    echo "⚠ WARNING: google-services.json not found in android/app/"
    echo "Firebase features may not work!"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✓ GoogleService-Info.plist found"
else
    echo "⚠ WARNING: GoogleService-Info.plist not found in ios/Runner/"
    echo "Firebase features may not work on iOS!"
fi
echo ""

echo "[5/5] Setup complete!"
echo ""
echo "===================================="
echo "   Next steps:"
echo "===================================="
echo "1. Connect your device or start emulator"
echo "2. Run: flutter run"
echo "3. Login with admin@fintracker.com / Admin@123"
echo ""
echo "===================================="
