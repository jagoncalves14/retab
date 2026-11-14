#!/bin/sh
# Builds Retab and assembles build/Retab.app (menu bar app, LSUIElement).
set -e

cd "$(dirname "$0")/.."

swift build -c release

APP="build/Retab.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp ".build/release/Retab" "$APP/Contents/MacOS/Retab"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp "Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "Resources/MenuBarIcon.pdf" "$APP/Contents/Resources/MenuBarIcon.pdf"
codesign --force --sign - "$APP"

# Package a drag-to-Applications disk image.
DMG="build/Retab.dmg"
STAGE="build/dmg-staging"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Retab" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"

echo "Built $APP and $DMG"
