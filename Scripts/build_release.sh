#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Configuration
APP_NAME="Media Organizer.app"
VERSION="1.0"
OUTPUT_DIR="Releases"
OUTPUT_DMG="${OUTPUT_DIR}/Media-Organizer-v${VERSION}.dmg"
BACKGROUND_IMAGE="Scripts/dmg_background.png"
STAGING_DIR="${OUTPUT_DIR}/Staging"

# Check if app path is provided
if [ -z "$1" ]; then
    echo "Usage: ./Scripts/build_release.sh /path/to/Media\ Organizer.app"
    echo "Please provide the path to your compiled application."
    exit 1
fi

SOURCE_APP="$1"

if [ ! -d "${SOURCE_APP}" ]; then
    echo "Error: App not found at ${SOURCE_APP}"
    exit 1
fi

echo "=============================================="
echo "📦 Building Release DMG for Media Organizer"
echo "=============================================="

# Ensure directories exist
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${STAGING_DIR}"

# Clean up old DMG if it exists
if [ -f "${OUTPUT_DMG}" ]; then
    echo "🗑️  Removing old DMG..."
    rm -f "${OUTPUT_DMG}"
fi

# Copy app to staging directory
echo "📋 Copying app to staging..."
cp -a "${SOURCE_APP}" "${STAGING_DIR}/"

# Build the DMG
echo "🎨 Creating beautiful DMG window..."
create-dmg \
  --volname "Install Media Organizer" \
  --volicon "Scripts/VolumeIcon.icns" \
  --background "${BACKGROUND_IMAGE}" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "${APP_NAME}" 150 200 \
  --hide-extension "${APP_NAME}" \
  --app-drop-link 450 200 \
  --hdiutil-quiet \
  "${OUTPUT_DMG}" \
  "${STAGING_DIR}/"

# Clean up staging
echo "🧹 Cleaning up..."
rm -rf "${STAGING_DIR}"

echo "✅ Success! Your release is ready at: ${OUTPUT_DMG}"
echo "You can now upload this file to GitHub Releases."
