#!/usr/bin/env bash
set -e

APP_NAME="Media Organizer.app"
DMG_NAME="Releases/Media-Organizer-Alpha-1.0.dmg"
BG_IMAGE="/Users/xavierscott/Documents/Media Organizer/Scripts/final_dmg_bg.png"
# Use a static name but with a space to ensure unique identification
VOL_NAME="Media Organizer Setup"

SOURCE_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "Media Organizer.app" -type d -path "*/Build/Products/Debug/*" -print0 | xargs -0 ls -td | head -n 1)

echo "📦 Building Release DMG..."
rm -f "$DMG_NAME" temp.dmg
mkdir -p Releases

# Create a 100MB HFS+ image
hdiutil create -size 100m -fs HFS+ -volname "$VOL_NAME" temp.dmg

# Mount it
MOUNT_PATH=$(hdiutil attach temp.dmg | grep "/Volumes/" | awk -F'\t' '{print $3}')
echo "📌 Mounted at: $MOUNT_PATH"

# Copy App and background
cp -a "$SOURCE_APP" "$MOUNT_PATH/"
mkdir "$MOUNT_PATH/.background"
cp "$BG_IMAGE" "$MOUNT_PATH/.background/bg.png"
ln -s /Applications "$MOUNT_PATH/Applications"

# Set Volume Icon
cp "/Users/xavierscott/Documents/Media Organizer/Scripts/VolumeIcon.icns" "$MOUNT_PATH/.VolumeIcon.icns"
setfile -a C "$MOUNT_PATH"

echo "🎨 Directing Finder to apply the background..."
osascript <<APPLESCRIPT
tell application "Finder"
    set diskName to "$VOL_NAME"
    set appName to "$APP_NAME"
    
    tell disk diskName
        open
        set current view of container window to icon view
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 120
        
        -- Set background using the internal DMG path
        set background picture of theViewOptions to file ".background:bg.png"
        
        -- Window styling (standard for DMGs)
        set statusbar visible of container window to false
        set toolbar visible of container window to false
        set sidebar width of container window to 0
        set the bounds of container window to {100, 100, 700, 500} -- 600x400
        
        -- Position icons
        set position of item appName to {150, 200}
        set position of item "Applications" to {450, 200}
        
        update items of container window
        delay 5 -- WAIT for Finder to actually write the .DS_Store
        close
    end tell
end tell
APPLESCRIPT

# Finalize the DMG
echo "💾 Finalizing..."
hdiutil detach "$MOUNT_PATH"
# Wait for detach to finish
sleep 2
hdiutil convert temp.dmg -format UDZO -o "$DMG_NAME"
rm temp.dmg
echo "✅ Success! Ready for upload."
