#!/bin/bash
# Compile le catalogue + PNG loose + Info.plist (requis pour l'icône sur l'écran d'accueil, surtout sideload).
set -euo pipefail

APP_DIR="${1:?Usage: embed_app_icons.sh <path/to/NeticAI.app>}"
SRCROOT="${2:-$(cd "$(dirname "$0")/.." && pwd)}"
ASSET_DIR="${SRCROOT}/Resources/Assets.xcassets"
ICON_SET="${ASSET_DIR}/AppIcon.appiconset"
PARTIAL_PLIST="${TMPDIR:-/tmp}/assetcatalog_generated_info.plist"

if [ ! -d "$APP_DIR" ]; then
  echo "error: app introuvable: $APP_DIR"
  exit 1
fi

if [ ! -d "$ASSET_DIR" ]; then
  echo "error: asset catalog introuvable: $ASSET_DIR"
  exit 1
fi

echo "==> actool (Assets.car + PNG loose)..."
xcrun actool "$ASSET_DIR" \
  --compile "$APP_DIR" \
  --platform iphoneos \
  --minimum-deployment-target 16.0 \
  --app-icon AppIcon \
  --target-device iphone \
  --compress-pngs \
  --enable-on-demand-resources NO \
  --standalone-icon-behavior all \
  --output-partial-info-plist "$PARTIAL_PLIST"

if [ ! -f "$APP_DIR/Assets.car" ]; then
  echo "error: Assets.car absent"
  exit 1
fi

# Fallback : copie manuelle des tailles critiques (noms attendus par SpringBoard)
embed_icon() {
  local src="$1"
  local dest="$2"
  if [ -f "${ICON_SET}/${src}" ]; then
    cp "${ICON_SET}/${src}" "${APP_DIR}/${dest}"
  fi
}

embed_icon "40.png"  "AppIcon20x20@2x.png"
embed_icon "60.png"  "AppIcon20x20@3x.png"
embed_icon "58.png"  "AppIcon29x29@2x.png"
embed_icon "87.png"  "AppIcon29x29@3x.png"
embed_icon "80.png"  "AppIcon40x40@2x.png"
embed_icon "120.png" "AppIcon40x40@3x.png"
embed_icon "120.png" "AppIcon60x60@2x.png"
embed_icon "180.png" "AppIcon60x60@3x.png"
embed_icon "1024.png" "AppIcon1024x1024.png"

if [ -f "$PARTIAL_PLIST" ]; then
  echo "==> Fusion Info.plist depuis actool..."
  /usr/libexec/PlistBuddy -c "Merge $PARTIAL_PLIST" "$APP_DIR/Info.plist" 2>/dev/null || true
fi

# CFBundleIconName + CFBundleIcons (obligatoire iOS 11+)
/usr/libexec/PlistBuddy -c "Print :CFBundleIconName" "$APP_DIR/Info.plist" >/dev/null 2>&1 \
  && /usr/libexec/PlistBuddy -c "Set :CFBundleIconName AppIcon" "$APP_DIR/Info.plist" \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "$APP_DIR/Info.plist"

/usr/libexec/PlistBuddy -c "Print :CFBundleIcons" "$APP_DIR/Info.plist" >/dev/null 2>&1 \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleIcons dict" "$APP_DIR/Info.plist"

/usr/libexec/PlistBuddy -c "Print :CFBundleIcons:CFBundlePrimaryIcon" "$APP_DIR/Info.plist" >/dev/null 2>&1 \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon dict" "$APP_DIR/Info.plist"

/usr/libexec/PlistBuddy -c "Print :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconName" "$APP_DIR/Info.plist" >/dev/null 2>&1 \
  && /usr/libexec/PlistBuddy -c "Set :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconName AppIcon" "$APP_DIR/Info.plist" \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconName string AppIcon" "$APP_DIR/Info.plist"

# CFBundleIconFiles — liste des noms sans extension
/usr/libexec/PlistBuddy -c "Delete :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles" "$APP_DIR/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles array" "$APP_DIR/Info.plist"
for name in AppIcon20x20 AppIcon29x29 AppIcon40x40 AppIcon60x60 AppIcon1024x1024; do
  /usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles: string ${name}" "$APP_DIR/Info.plist"
done

LOOSE_COUNT=$(find "$APP_DIR" -maxdepth 1 -name 'AppIcon*.png' 2>/dev/null | wc -l | tr -d ' ')
ICON_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconName" "$APP_DIR/Info.plist" 2>/dev/null || echo "")
CAR_SIZE=$(wc -c < "$APP_DIR/Assets.car" | tr -d ' ')

echo "OK: Assets.car=${CAR_SIZE}o, PNG loose=${LOOSE_COUNT}, CFBundleIconName=${ICON_NAME}"
ls -la "$APP_DIR"/AppIcon*.png 2>/dev/null || true
