#!/bin/bash
#
#  release.sh
#  SideKick
#
#  Created by Kévin Naudin on 2026-06-23.
#
#  Cuts a Sparkle release: builds & notarizes the app, publishes a GitHub Release
#  with the .dmg, generates/signs the appcast (EdDSA), and commits the appcast so
#  it is served from main via raw.githubusercontent.com (the app's SUFeedURL).
#
#  Usage:
#    ./release.sh [version] [--skip-build] [--no-push] [--notes "text"]
#
#    version        Marketing version to release (e.g. 4.1.0). Defaults to the
#                   project's MARKETING_VERSION.
#    --skip-build   Reuse the existing build/SideKick.dmg (skip build_and_notarize).
#    --no-push      Generate everything but do not create the GitHub Release,
#                   commit, or push (dry run of the local artifacts).
#    --notes "..."  Release notes (defaults to auto-generated notes).
#
#  Prerequisites:
#    - gh CLI authenticated (`gh auth status`)
#    - Notarization env vars for build_and_notarize.sh (NOTARY_KEY_PATH/ID/ISSUER_ID)
#    - The Sparkle EdDSA private key in the Keychain under account "onit-sidekick"
#      (generated with generate_keys --account onit-sidekick).

set -euo pipefail

# ───────────────────────── Configuration ─────────────────────────
APP_NAME="SideKick"
GH_REPO="synth-inc/onit"
SPARKLE_ACCOUNT="onit-sidekick"
CASK_NAME="onit-sidekick"
TAP_DIR="${TAP_DIR:-$HOME/SynthInc/homebrew-tap}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
APPCAST="$REPO_ROOT/appcast.xml"
WORK="$BUILD_DIR/appcast-work"

# ───────────────────────── Parse arguments ─────────────────────────
VERSION=""
SKIP_BUILD=false
NO_PUSH=false
NOTES=""
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-build) SKIP_BUILD=true ;;
    --no-push)    NO_PUSH=true ;;
    --notes)      NOTES="$2"; shift ;;
    -*)           echo "Unknown option: $1"; exit 1 ;;
    *)            VERSION="$1" ;;
  esac
  shift
done

# ───────────────────────── Resolve version ─────────────────────────
if [ -z "$VERSION" ]; then
  VERSION=$(xcodebuild -project "$SCRIPT_DIR/OnitSideKick.xcodeproj" -scheme OnitSideKick \
    -showBuildSettings 2>/dev/null | awk -F' = ' '/ MARKETING_VERSION /{print $2; exit}')
fi
[ -n "$VERSION" ] || { echo "❌ Could not resolve a version."; exit 1; }
BUILD=$(xcodebuild -project "$SCRIPT_DIR/OnitSideKick.xcodeproj" -scheme OnitSideKick \
  -showBuildSettings 2>/dev/null | awk -F' = ' '/ CURRENT_PROJECT_VERSION /{print $2; exit}')
TAG="v$VERSION"
DMG_VERSIONED="$APP_NAME-$VERSION.dmg"
echo "🚀 Releasing $APP_NAME $VERSION (build $BUILD, tag $TAG)"

# ───────────────────────── Locate Sparkle tools ─────────────────────────
# Override with SPARKLE_BIN=/path/to/Sparkle/bin if auto-detection fails.
SPARKLE_BIN="${SPARKLE_BIN:-}"
if [ -z "$SPARKLE_BIN" ] || [ ! -x "$SPARKLE_BIN/generate_appcast" ]; then
  SPARKLE_BIN=$(find "$HOME/Library/Developer/Xcode/DerivedData" \
    -path '*artifacts/sparkle/Sparkle/bin/generate_appcast' 2>/dev/null | head -1 | xargs -I{} dirname {})
fi
[ -x "$SPARKLE_BIN/generate_appcast" ] || {
  echo "❌ generate_appcast not found. Build the app once in Xcode (to fetch Sparkle via SPM),"
  echo "   or set SPARKLE_BIN=/path/to/Sparkle/bin."
  exit 1
}
echo "🔧 Sparkle tools: $SPARKLE_BIN"

# ───────────────────────── Build & notarize ─────────────────────────
if [ "$SKIP_BUILD" = false ]; then
  echo "🏗  Building & notarizing…"
  "$SCRIPT_DIR/build_and_notarize.sh"
fi
[ -f "$DMG_PATH" ] || { echo "❌ Missing $DMG_PATH (build failed or --skip-build with no dmg)."; exit 1; }

# ───────────────────────── Prepare appcast work dir ─────────────────────────
rm -rf "$WORK"; mkdir -p "$WORK"
cp "$DMG_PATH" "$WORK/$DMG_VERSIONED"
# Preserve previously published items so the appcast keeps its history.
[ -f "$APPCAST" ] && cp "$APPCAST" "$WORK/appcast.xml"

# ───────────────────────── Publish GitHub Release ─────────────────────────
if [ "$NO_PUSH" = false ]; then
  echo "📦 Creating GitHub Release ${TAG}…"
  # Upload BOTH the versioned DMG (referenced by the appcast enclosure) and a
  # constant-named copy ("$DMG_PATH" == "$APP_NAME.dmg") so the stable download
  # permalink stays alive across versions:
  #   https://github.com/$GH_REPO/releases/latest/download/$APP_NAME.dmg
  # NOTE: the constant-named copy is kept OUT of "$WORK" so generate_appcast
  # (which scans "$WORK") still produces a single, correctly-versioned item.
  if gh release view "$TAG" --repo "$GH_REPO" >/dev/null 2>&1; then
    gh release upload "$TAG" "$WORK/$DMG_VERSIONED" "$DMG_PATH" --repo "$GH_REPO" --clobber
  else
    if [ -n "$NOTES" ]; then
      gh release create "$TAG" "$WORK/$DMG_VERSIONED" "$DMG_PATH" --repo "$GH_REPO" \
        --title "$APP_NAME $VERSION" --notes "$NOTES"
    else
      gh release create "$TAG" "$WORK/$DMG_VERSIONED" "$DMG_PATH" --repo "$GH_REPO" \
        --title "$APP_NAME $VERSION" --generate-notes
    fi
  fi
fi

# ───────────────────────── Generate & sign appcast ─────────────────────────
echo "✍️  Generating signed appcast…"
"$SPARKLE_BIN/generate_appcast" \
  --account "$SPARKLE_ACCOUNT" \
  --download-url-prefix "https://github.com/$GH_REPO/releases/download/$TAG/" \
  -o "$WORK/appcast.xml" \
  "$WORK"

cp "$WORK/appcast.xml" "$APPCAST"
echo "✅ appcast.xml updated at $APPCAST"

# ───────────────────────── Update Homebrew cask ─────────────────────────
CASK_FILE="$TAP_DIR/Casks/$CASK_NAME.rb"
if [ "$NO_PUSH" = false ] && [ -f "$CASK_FILE" ]; then
  echo "🍺 Updating Homebrew cask…"
  SHA=$(shasum -a 256 "$WORK/$DMG_VERSIONED" | awk '{print $1}')
  sed -i '' -E "s/^  version \".*\"/  version \"$VERSION,$BUILD\"/" "$CASK_FILE"
  sed -i '' -E "s/^  sha256 \".*\"/  sha256 \"$SHA\"/" "$CASK_FILE"
  ( cd "$TAP_DIR"
    git add "Casks/$CASK_NAME.rb"
    git commit -m "$CASK_NAME $VERSION" || echo "ℹ️  cask unchanged."
    git push )
  echo "✅ Cask updated → brew install --cask $CASK_NAME"
elif [ "$NO_PUSH" = true ]; then
  echo "🧪 --no-push: cask not updated."
else
  echo "ℹ️  Cask file not found ($CASK_FILE) — skipping cask update."
fi

# ───────────────────────── Commit & push appcast ─────────────────────────
if [ "$NO_PUSH" = false ]; then
  ( cd "$REPO_ROOT"
    git add appcast.xml
    git commit -m "Release $VERSION" || echo "ℹ️  appcast unchanged, nothing to commit."
    git push origin main )
  echo "🎉 Released $APP_NAME $VERSION. Sparkle clients will see it within their check interval."
else
  echo "🧪 --no-push: appcast generated locally, no Release/commit/push performed."
fi
