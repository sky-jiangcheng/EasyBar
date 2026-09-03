#!/usr/bin/env bash
set -euo pipefail

# Build, sign, and package EasyBar for Mac App Store submission.
#
# Required env:
#   APP_VERSION        - marketing version, e.g. 1.14.0
#   SIGNING_IDENTITY   - codesign identity, e.g. "Apple Distribution: ... (TEAMID)"
# Optional env:
#   BUILD_NUMBER       - build version, default 1
#   BUNDLE_ID          - default com.jiangcheng.EasyBar
#   APP_NAME           - default EasyBar
#   INSTALLER_IDENTITY - pkg signing identity, defaults to SIGNING_IDENTITY
#   PROVISIONING_PROFILE - path to .mobileprovision to embed, optional

APP_NAME="${APP_NAME:-EasyBar}"
BUNDLE_ID="${BUNDLE_ID:-com.jiangcheng.EasyBar}"
APP_VERSION="${APP_VERSION:-0.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:?SIGNING_IDENTITY is required}"
INSTALLER_IDENTITY="${INSTALLER_IDENTITY:-$SIGNING_IDENTITY}"
MIN_SYSTEM_VERSION="${MIN_SYSTEM_VERSION:-14.0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
PKG_PATH="$DIST_DIR/$APP_NAME.pkg"

# SPM product name differs from the app name; rename the binary on copy.
SPM_PRODUCT_NAME="StatusBar Pro"
ENTITLEMENTS="$ROOT_DIR/Sources/StatusBar Pro/Resources/EasyBar.entitlements"
APPCONSET="$ROOT_DIR/Sources/StatusBar Pro/Resources/Assets.xcassets/AppIcon.appiconset"

echo "==> Building release binary (swift build -c release)"
swift build -c release --scratch-path "$ROOT_DIR/.build"
BIN_DIR="$(swift build -c release --scratch-path "$ROOT_DIR/.build" --show-bin-path)"
BINARY="$BIN_DIR/$SPM_PRODUCT_NAME"
[ -f "$BINARY" ] || { echo "binary not found: $BINARY" >&2; exit 1; }

echo "==> Assembling $APP_NAME.app"
rm -rf "$APP_BUNDLE" "$PKG_PATH"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BINARY" "$APP_MACOS/$APP_NAME"
chmod +x "$APP_MACOS/$APP_NAME"

cat > "$APP_CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "==> Generating AppIcon.icns"
ICONSET="$DIST_DIR/AppIcon.iconset"
rm -rf "$ICONSET"
cp -R "$APPCONSET" "$ICONSET"
iconutil -c icns "$ICONSET" -o "$APP_RESOURCES/AppIcon.icns"

if [ -n "${PROVISIONING_PROFILE:-}" ] && [ -f "$PROVISIONING_PROFILE" ]; then
  cp "$PROVISIONING_PROFILE" "$APP_CONTENTS/embedded.provisionprofile"
fi

echo "==> Codesigning with: $SIGNING_IDENTITY"
codesign --force --sign "$SIGNING_IDENTITY" --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

echo "==> Packaging .pkg with: $INSTALLER_IDENTITY"
productbuild --component "$APP_BUNDLE" /Applications --sign "$INSTALLER_IDENTITY" "$PKG_PATH"

echo "==> Done: $PKG_PATH"
