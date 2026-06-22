#!/bin/bash
set -euo pipefail

# Usage:
#   ./build_and_notarize.sh                      - Full build, sign, and notarize
#   ./build_and_notarize.sh --beta               - Full build with BETA flag enabled
#   ./build_and_notarize.sh --dmg-only           - Create DMG only (no build/sign/notarize)
#   ./build_and_notarize.sh --help               - Show this help

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  (none)          Full build, sign, notarize, and create DMG"
  echo "  --beta          Full build with BETA flag enabled (includes debug features)"
  echo "  --dmg-only      Create DMG only using existing app in build/"
  echo "  --help          Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                     # Full build and notarization"
  echo "  $0 --beta             # Build with BETA features enabled"
  echo "  $0 --dmg-only         # Quick DMG creation for testing layout"
  echo ""
  echo "Note: All modes requiring notarization need NOTARY_KEY_PATH, NOTARY_KEY_ID, and NOTARY_ISSUER_ID to be set"
  exit 0
fi

########################################
# 🔧 Configuration
########################################
APP_NAME="SideKick"
SCHEME="OnitSideKick"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
DMG_RW_PATH="$BUILD_DIR/$APP_NAME-temp.dmg"
DMG_LAYOUT_DIR="$BUILD_DIR/dmg_layout"

SIGN_ID="Developer ID Application: Synthetic Exploration, Inc (TYC9PKBMB6)"

# Notarization credentials (App Store Connect API key)
NOTARY_KEY_PATH="${NOTARY_KEY_PATH:-}"
NOTARY_KEY_ID="${NOTARY_KEY_ID:-}"
NOTARY_ISSUER_ID="${NOTARY_ISSUER_ID:-}"

# Parse arguments
DMG_ONLY=false
BETA_BUILD=false
if [[ "${1:-}" == "--dmg-only" ]]; then
  DMG_ONLY=true
  echo "🎨 Mode DMG only - Skipping build, signing and notarization"
elif [[ "${1:-}" == "--beta" ]]; then
  BETA_BUILD=true
  echo "🧪 BETA build - Including debug features via BETA compilation flag"
fi

if [ "$DMG_ONLY" = false ]; then

  ########################################
  # 🧹 Clean + Archive
  ########################################
  echo "🧹 Cleaning and archiving..."
  xcodebuild clean -scheme "$SCHEME" -configuration Release >/dev/null

  # Build with BETA flag if enabled
  # Note: arm64 only
  if [ "$BETA_BUILD" = true ]; then
    echo "🧪 Building with BETA compilation flag..."
    xcodebuild -scheme "$SCHEME" -configuration Release \
      -archivePath "$ARCHIVE_PATH" \
      -destination "generic/platform=macOS" \
      ARCHS="arm64" \
      SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) ONIT_BETA' \
      GCC_PREPROCESSOR_DEFINITIONS='$(inherited) ONIT_BETA=1' \
      archive >/dev/null
  else
    xcodebuild -scheme "$SCHEME" -configuration Release \
      -archivePath "$ARCHIVE_PATH" \
      -destination "generic/platform=macOS" \
      ARCHS="arm64" archive >/dev/null
  fi

  echo "✅ Archive complete."

  ########################################
  # 📦 Extract .app
  ########################################
  echo "📂 Extracting .app from archive..."
  rm -rf "$APP_PATH"
  cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME.app" "$BUILD_DIR/"

  ########################################
  # 🔧 Replace provisioning profile with Developer ID profile
  ########################################
  echo "🔧 Installing Developer ID provisioning profile..."
  find "$APP_PATH" -name "embedded.provisionprofile" -delete
  find "$APP_PATH" -name "*.provisionprofile" -delete
  cp "Onit_Developer_ID.provisionprofile" "$APP_PATH/Contents/embedded.provisionprofile"
  echo "✅ Developer ID profile installed"

  # Use entitlements file directly (no transformation needed)
  DIST_ENTITLEMENTS="OnitSideKick/OnitSideKick.entitlements"

  ########################################
  # 🔏 Signing with Developer ID
  ########################################
  echo "🔏 Signing with Developer ID (no provisioning profile)..."

  # Sign all internal executables
  find "$APP_PATH/Contents/Resources" -type f -name "rg" | while read -r binary; do
    echo "  Signing: $binary"
    codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$binary"
  done

  # Sign Sparkle framework's nested executables (helper apps + tools)
  find "$APP_PATH/Contents/Frameworks/Sparkle.framework" -type f -perm +111 -exec \
    codesign --force --options runtime --timestamp --sign "$SIGN_ID" {} \;

  # Sign every embedded framework: SPM dependencies can arrive with upstream
  # signatures that notarization rejects, so re-sign each one.
  for fw in "$APP_PATH/Contents/Frameworks"/*.framework; do
    echo "  Signing framework: $fw"
    codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$fw"
  done

  # Sign main bundle with distribution entitlements
  codesign --force --options runtime --timestamp \
    --entitlements "$DIST_ENTITLEMENTS" \
    --sign "$SIGN_ID" "$APP_PATH"

  ########################################
  # 🔍 Verification
  ########################################
  echo "🔍 Verifying signatures..."
  codesign --verify --deep --strict --verbose=2 "$APP_PATH"

  echo "⏳ Waiting for system to release locks (5s)..."
  sleep 5
  sync

  ########################################
  # 📝 Notarization Credentials Check
  ########################################
  if [[ -z "$NOTARY_KEY_PATH" || -z "$NOTARY_KEY_ID" || -z "$NOTARY_ISSUER_ID" ]]; then
    echo "❌ Notarization credentials missing!"
    echo "   export NOTARY_KEY_PATH=<path to AuthKey_XXX.p8>"
    echo "   export NOTARY_KEY_ID=<Key ID>"
    echo "   export NOTARY_ISSUER_ID=<Issuer ID>"
    exit 1
  fi
else
  # Check if app exists
  if [ ! -d "$APP_PATH" ]; then
    echo "❌ $APP_PATH not found! Build the app first or run without --dmg-only"
    exit 1
  fi
  echo "✅ Using existing app at $APP_PATH"
fi

########################################
# 🎨 Custom DMG Layout
########################################
echo "🎨 Preparing custom DMG layout..."

# Cleaning
echo "🧹 Ensuring no conflicting volumes are mounted..."
for vol in "/Volumes/$APP_NAME" "/Volumes/$APP_NAME 1" "/Volumes/$APP_NAME 2"; do
  if [ -d "$vol" ]; then
    echo "  Cleaning up $vol"
    # First try to detach if it's a mounted volume
    hdiutil detach "$vol" -force 2>/dev/null || true
    sleep 1
    # If still exists (ghost directory), remove it
    if [ -d "$vol" ] && ! mount | grep -q "$vol"; then
      echo "  Removing ghost directory $vol"
      rm -rf "$vol" 2>/dev/null || sudo rm -rf "$vol" 2>/dev/null || true
    fi
  fi
done

rm -rf "$DMG_LAYOUT_DIR" "$DMG_PATH" "$DMG_RW_PATH"
sleep 2  # Give system more time to release resources

# Structure
mkdir -p "$DMG_LAYOUT_DIR/.background"
cp -R "$APP_PATH" "$DMG_LAYOUT_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_LAYOUT_DIR/Applications"

# Background
if [ ! -f "dmg_assets/background.png" ]; then
  echo "⚠️ No background at dmg_assets/background.png"
  sips -s format png --resampleWidth 493 /System/Library/CoreServices/DefaultDesktop.heic --out "$DMG_LAYOUT_DIR/.background/background.png" 2>/dev/null || true
fi

if [ -f "dmg_assets/background.png" ]; then
  cp "dmg_assets/background.png" "$DMG_LAYOUT_DIR/.background/background.png"
fi

########################################
# 💽 Create Writable DMG
########################################
echo "💽 Creating writable DMG..."
# Use a unique temp volume name to avoid macOS security restrictions
# (macOS blocks creating volume "Onit" containing "Onit.app" directly)
TEMP_VOL_NAME="${APP_NAME}-Build-$$"
hdiutil create -volname "$TEMP_VOL_NAME" \
  -srcfolder "$DMG_LAYOUT_DIR" \
  -ov -fs HFS+ -format UDRW "$DMG_RW_PATH"

DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_RW_PATH" | grep '^/dev/' | head -n1 | awk '{print $1}')
sleep 2

# Verify the temp volume is mounted
if [ ! -d "/Volumes/$TEMP_VOL_NAME" ]; then
  echo "❌ Volume /Volumes/$TEMP_VOL_NAME not mounted!"
  exit 1
fi

# Rename volume to final name
echo "📝 Renaming volume to $APP_NAME..."
diskutil rename "/Volumes/$TEMP_VOL_NAME" "$APP_NAME"
sleep 1

# Verify the renamed volume
if [ ! -d "/Volumes/$APP_NAME" ]; then
  echo "❌ Volume rename failed! /Volumes/$APP_NAME not found"
  exit 1
fi

echo "✅ Volume mounted at /Volumes/$APP_NAME"

########################################
# 🪄 Customize Finder Layout
########################################
echo "🪄 Customizing Finder window..."
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 593, 367}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 88
        set background picture of viewOptions to file ".background:background.png"

        -- Position items (Applications symlink already exists)
        set position of item "$APP_NAME.app" of container window to {147, 125}
        set position of item "Applications" of container window to {346, 125}
        close
        open
        update without registering applications
        delay 1
        eject
    end tell
end tell
EOF

sleep 1
# The AppleScript should have ejected it, but try to detach just in case
hdiutil detach "$DEVICE" 2>/dev/null || true

########################################
# 📦 Convert & Sign DMG
########################################
echo "📦 Converting DMG to compressed format..."
hdiutil convert "$DMG_RW_PATH" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"

if [ "$DMG_ONLY" = false ]; then
  echo "🔏 Signing DMG..."
  codesign --force --timestamp --sign "$SIGN_ID" "$DMG_PATH"

  ########################################
  # 🍏 Notarization
  ########################################
  echo "📝 Submitting DMG to Apple Notary Service..."
  SUBMISSION_OUTPUT=$(xcrun notarytool submit "$DMG_PATH" \
    --key "$NOTARY_KEY_PATH" \
    --key-id "$NOTARY_KEY_ID" \
    --issuer "$NOTARY_ISSUER_ID" \
    --wait 2>&1)

  echo "$SUBMISSION_OUTPUT"

  # Check if notarization was successful
  if echo "$SUBMISSION_OUTPUT" | grep -q "status: Accepted"; then
    echo "✅ Notarization accepted!"
  else
    echo "❌ Notarization failed or invalid status"
    echo "$SUBMISSION_OUTPUT"
    exit 1
  fi

  ########################################
  # 🪄 Stapling with retry
  ########################################
  MAX_WAIT=90
  WAIT_INTERVAL=10
  WAITED=0

  echo "⏳ Waiting for notarization ticket to propagate..."

  while [ $WAITED -lt $MAX_WAIT ]; do
    if xcrun stapler staple "$DMG_PATH" 2>&1; then
      echo "✅ Stapling successful!"
      xcrun stapler validate "$DMG_PATH"
      break
    else
      echo "⚠️  Ticket not ready yet… retrying in $WAIT_INTERVAL seconds"
      sleep $WAIT_INTERVAL
      WAITED=$((WAITED + WAIT_INTERVAL))
    fi
  done

  if [ $WAITED -ge $MAX_WAIT ]; then
    echo "❌ Ticket still not available after $MAX_WAIT seconds"
    exit 1
  fi

  ########################################
  # ✅ Final Verification
  ########################################
  echo "🔐 Final Gatekeeper check..."
  spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG_PATH"

  echo ""
  echo "🎉 SUCCESS! Your app is ready for distribution."
  echo "📍 DMG location: $DMG_PATH"
  echo ""
  if [ "$BETA_BUILD" = true ]; then
    echo "🧪 BETA build with debug features enabled"
  fi
  echo "✅ Signed, notarized, and stapled DMG"
  echo "✅ Includes custom Finder layout and background"
  echo ""
else
  echo ""
  echo "🎉 DMG created successfully!"
  echo "📍 DMG location: $DMG_PATH"
  echo ""
  echo "⚠️  DMG NOT signed or notarized (--dmg-only mode)"
  echo "✅ Includes custom Finder layout and background"
  echo ""
fi
