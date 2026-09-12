#!/bin/bash
# Builds the Flutter release APK and renames it to match the app version.

echo "Building release APK..."
flutter build apk --release

# Extract version from pubspec.yaml
VERSION=$(grep '^version: ' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 1)
APK_NAME="bajatelo-${VERSION}.apk"

# Rename and move the APK
cp build/app/outputs/flutter-apk/app-release.apk "build/app/outputs/flutter-apk/${APK_NAME}"

echo "Done! Your APK is ready at: build/app/outputs/flutter-apk/${APK_NAME}"
