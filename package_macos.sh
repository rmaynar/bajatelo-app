#!/bin/bash

# Extract version from pubspec.yaml (gets just '0.0.2' without the build number)
VERSION=$(grep '^version: ' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)

APP_NAME="Bajatelo"
APP_DIR="build/macos/Build/Products/Release/$APP_NAME.app"
DMG_NAME="build/macos/Build/Products/Release/${APP_NAME}-${VERSION}.dmg"
DMG_STAGING_DIR="build/macos/Build/Products/Release/dmg_staging"

if [ ! -d "$APP_DIR" ]; then
    echo "Error: $APP_DIR not found. Run 'flutter build macos --release' first."
    exit 1
fi

echo "Packaging $APP_NAME.app into $DMG_NAME..."
rm -rf "$DMG_STAGING_DIR"
mkdir -p "$DMG_STAGING_DIR"
cp -R "$APP_DIR" "$DMG_STAGING_DIR/"
ln -s /Applications "$DMG_STAGING_DIR/Applications"
rm -f "$DMG_NAME"

# Note: The volname is still just "Bajatelo" for a clean mounted drive name
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING_DIR" -ov -format UDZO "$DMG_NAME"
rm -rf "$DMG_STAGING_DIR"
echo "Success! Created at $DMG_NAME"
