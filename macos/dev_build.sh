#!/usr/bin/env bash
#
# dev_build.sh — local Debug build for everyday development.
#
# Builds the Debug configuration, then RE-SIGNS the app with the stable team
# Developer ID identity. We re-sign because automatic "Apple Development"
# signing can rotate between two certs, which changes the code signature's
# Designated Requirement — and macOS keys Accessibility (TCC) grants to that
# requirement. A stable Developer ID signature means you grant Accessibility
# once and it sticks across rebuilds.
#
# Usage:
#   ./dev_build.sh            Build, re-sign, and launch from DerivedData
#   ./dev_build.sh --install  Also copy into /Applications (for Spotlight) and launch that
#
set -euo pipefail

cd "$(dirname "$0")"

PROJECT="OnitSideKick.xcodeproj"
SCHEME="OnitSideKick"
SIGN_ID="Developer ID Application: Synthetic Exploration, Inc (TYC9PKBMB6)"
ENTITLEMENTS="OnitSideKick/OnitSideKick.entitlements"
PROFILE="Onit_Developer_ID.provisionprofile"

INSTALL=0
[[ "${1:-}" == "--install" ]] && INSTALL=1

# Resolve the built app path and name from build settings (auto-adapts to renames).
APP_PATH=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -showBuildSettings 2>/dev/null \
  | awk -F' = ' '/ BUILT_PRODUCTS_DIR /{d=$2} / FULL_PRODUCT_NAME /{n=$2} END{print d"/"n}')
APP_NAME=$(basename "$APP_PATH" .app)

echo "🛑 Quitting any running ${APP_NAME}..."
osascript -e "quit app \"${APP_NAME}\"" 2>/dev/null || true
pkill -f "${APP_NAME}" 2>/dev/null || true
sleep 1

echo "🔨 Building (Debug)..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -destination 'platform=macOS' build >/dev/null

if [[ ! -d "$APP_PATH" ]]; then
  echo "❌ Built app not found at: $APP_PATH" >&2
  exit 1
fi
echo "📦 Built: $APP_PATH"

echo "🔏 Re-signing with Developer ID..."
find "$APP_PATH" -name "embedded.provisionprofile" -delete
cp "$PROFILE" "$APP_PATH/Contents/embedded.provisionprofile"

# Nested ripgrep binary
find "$APP_PATH/Contents/Resources" -type f -name "rg" 2>/dev/null | while read -r b; do
  codesign --force --options runtime --sign "$SIGN_ID" "$b"
done

# Sparkle framework's nested executables
if [[ -d "$APP_PATH/Contents/Frameworks/Sparkle.framework" ]]; then
  find "$APP_PATH/Contents/Frameworks/Sparkle.framework" -type f -perm +111 -exec \
    codesign --force --options runtime --sign "$SIGN_ID" {} \;
fi

# Every embedded framework
for fw in "$APP_PATH/Contents/Frameworks"/*.framework; do
  [[ -d "$fw" ]] && codesign --force --options runtime --sign "$SIGN_ID" "$fw"
done

# Main bundle with entitlements
codesign --force --options runtime --entitlements "$ENTITLEMENTS" --sign "$SIGN_ID" "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
echo "✅ Signature valid"

LAUNCH="$APP_PATH"
if [[ "$INSTALL" == "1" ]]; then
  DEST="/Applications/${APP_NAME}.app"
  echo "📲 Installing to ${DEST}..."
  rm -rf "$DEST"
  cp -R "$APP_PATH" "$DEST"
  LAUNCH="$DEST"
fi

echo "🚀 Launching: $LAUNCH"
open "$LAUNCH"
