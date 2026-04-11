#!/usr/bin/env bash
set -e

VOL_NAME="Media_Test_$(date +%s)"
DMG_PATH="Releases/Media-Organizer-Alpha-1.0.dmg"
BG_IMAGE="/Users/xavierscott/Documents/Media Organizer/Scripts/test_bg.png"
SOURCE_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "Media Organizer.app" -type d -path "*/Build/Products/Debug/*" | head -n 1)

rm -f "$DMG_PATH" temp.dmg
hdiutil create -size 100m -fs HFS+ -volname "$VOL_NAME" temp.dmg
MOUNT_PATH=$(hdiutil attach temp.dmg | grep "/Volumes/" | awk -F'\t' '{print $3}')

cp -a "$SOURCE_APP" "$MOUNT_PATH/"
mkdir "$MOUNT_PATH/.background"
cp "$BG_IMAGE" "$MOUNT_PATH/.background/bg.png"
ln -s /Applications "$MOUNT_PATH/Applications"

echo "🎨 Directing Finder..."
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set theViewOptions to icon view options of container window
        set background picture of theViewOptions to file ".background:bg.png"
        set icon size of theViewOptions to 128
        set position of item "Media Organizer.app" to {150, 200}
        set position of item "Applications" to {450, 200}
        -- Force a write to .DS_Store
        update items of container window
        delay 5
        close
    end tell
end tell
APPLESCRIPT

hdiutil detach "$MOUNT_PATH"
hdiutil convert temp.dmg -format UDZO -o "$DMG_PATH"
rm temp.dmg
