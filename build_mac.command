#!/bin/bash
cd "$(dirname "$0")"

# Script pour générer le projet Xcode sur un Mac

# Vérifie si xcodegen est installé
if ! command -v xcodegen &> /dev/null
then
    echo "XcodeGen n'est pas installé. Installation via Homebrew..."
    if ! command -v brew &> /dev/null
    then
        echo "Erreur: Homebrew n'est pas installé."
        echo "Installez-le d'abord depuis https://brew.sh"
        exit 1
    fi
    brew install xcodegen
fi

echo "Génération du projet Xcode..."
xcodegen generate

echo "Génération terminée !"
echo "Ouverture de Xcode..."
open NeticAI.xcodeproj
