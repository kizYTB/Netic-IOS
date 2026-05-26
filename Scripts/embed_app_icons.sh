#!/bin/bash
# Script de sécurité pour l'injection des icônes

APP_DIR="$1"
SRCROOT="$2"

if [ -z "$APP_DIR" ] || [ -z "$SRCROOT" ]; then
    exit 0 # On ne fait rien si les arguments manquent
fi

ICON_SOURCE="$SRCROOT/Resources/Assets.xcassets/AppIcon.appiconset/icon.png"

if [ -f "$ICON_SOURCE" ]; then
    cp "$ICON_SOURCE" "$APP_DIR/AppIcon.png" 2>/dev/null || true
fi
