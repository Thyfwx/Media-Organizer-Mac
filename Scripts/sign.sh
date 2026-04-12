#!/usr/bin/env bash
# Professional Signing Script for Media Organizer
set -e

REPO_PATH="/Users/xavierscott/Documents/Media Organizer"

echo "📝 Staging changes..."
git -C "$REPO_PATH" add .

echo "🖋️ Requesting Signature (Watch for 1Password/TouchID prompt)..."
git -C "$REPO_PATH" commit -m "Verified: Upgrade to Alpha 1.0.1 with Forensic AI and In-App Updater" -S

echo "🚀 Pushing to GitHub..."
git -C "$REPO_PATH" push origin main --force

echo "✅ Everything is Verified and Live!"
