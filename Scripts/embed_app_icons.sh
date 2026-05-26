#!/bin/bash
# Ce script injecte les icônes d'application dans le bundle .app

APP_DIR="$1"
SRCROOT="$2"

if [ -z "$APP_DIR" ] || [ -z "$SRCROOT" ]; then
    echo "Usage: $0 <app_dir> <srcroot>"
    exit 1
fi

echo "Injecting icons into $APP_DIR..."

# Copier l'icône marketing (1024x1024)
cp "$SRCROOT/Resources/Assets.xcassets/AppIcon.appiconset/icon.png" "$APP_DIR/AppIcon.png"

# Note: Xcode s'occupe normalement de générer les différentes tailles lors de l'archive
# si le dossier Resources est bien inclus dans le projet.
