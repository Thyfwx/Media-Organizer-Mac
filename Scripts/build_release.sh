#!/usr/bin/env bash
set -e

APP_NAME="Media Organizer.app"
OUTPUT_DMG="Releases/Media-Organizer-Alpha-1.0.dmg"
BACKGROUND_IMAGE="/Users/xavierscott/Documents/Media Organizer/Scripts/dmg_background.png"
# Use a static name
VOL_NAME="Media Organizer"

# Find latest build
SOURCE_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "Media Organizer.app" -type d -path "*/Build/Products/Debug/*" -print0 | xargs -0 ls -td | head -n 1)

echo "📦 Building Release DMG from: $SOURCE_APP"
rm -f "$OUTPUT_DMG"
mkdir -p Releases

# Use create-dmg with absolute paths and a specific window size
# We add a delay to ensure Finder can write the .DS_Store
/opt/homebrew/bin/create-dmg \
  --volname "$VOL_NAME" \
  --volicon "Scripts/VolumeIcon.icns" \
  --background "$BACKGROUND_IMAGE" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 120 \
  --icon "$APP_NAME" 150 200 \
  --hide-extension "$APP_NAME" \
  --app-drop-link 450 200 \
  "$OUTPUT_DMG" \
  "$SOURCE_APP"

echo "✅ DMG Built. Verifying background locally..."
# Check if the background exists inside the DMG
hdiutil mount "$OUTPUT_DMG" -mountpoint "/Volumes/Verify"
if [ -f "/Volumes/Verify/.background/dmg_background.png" ]; then
    echo "✅ Background file exists inside DMG."
else
    echo "❌ ERROR: Background file MISSING inside DMG."
fi
hdiutil detach "/Volumes/Verify"
