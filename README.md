# Netic iOS App

Ce répertoire contient le code source de l'application iOS native pour Netic. 
L'application est construite avec **SwiftUI** et utilise un **WKWebView** optimisé pour afficher l'application web Netic.

## Structure du projet

Ce projet utilise **XcodeGen** pour gérer le fichier `.xcodeproj`. Cela évite les conflits de fichiers et facilite l'intégration continue.

- `project.yml` : Configuration du projet (cibles, sources, permissions).
- `Sources/` : Code source SwiftUI.
- `Resources/` : Assets, icônes et logos.

## Installation et Compilation (Local sur Mac)

Si vous voulez compiler le projet sur votre Mac :

1. Installez XcodeGen : `brew install xcodegen`
2. Générez le projet : `xcodegen generate`
3. Ouvrez le fichier généré `Netic.xcodeproj` dans Xcode.

## Build Automatisé (Codemagic)

Le workflow Codemagic est déjà configuré pour installer XcodeGen et générer le projet automatiquement avant le build. Vous n'avez rien à faire d'autre que de lancer le build sur l'interface Codemagic.

---

## Fonctionnalités Mobile & Logique

L'application n'est pas qu'un simple navigateur, elle implémente une logique native complète pour s'intégrer au site web Netic :

### 1. Bridge JavaScript (Bidirectionnel)
L'application expose une interface `window.AndroidBridge` (pour compatibilité avec le code existant) et utilise `window.webkit.messageHandlers.netic` pour la communication native.

**Depuis le Web vers le Natif :**
- `vibrate` : Déclenche un retour haptique sur l'iPhone.
- `logout` : Nettoie tous les cookies et données locales pour une déconnexion sécurisée.
- `checkForUpdates` : Force une vérification de mise à jour via le serveur Netic.

**Depuis le Natif vers le Web :**
- L'app injecte la version actuelle au chargement.
- L'app envoie un événement `netic-update-available` si une nouvelle version est détectée sur `app.neticai.fr/mobile/version.xml`.

### 2. Gestion d'État (SwiftUI + Combine)
- **WebViewState** : Gère en temps réel l'état de chargement, les erreurs de navigation et la disponibilité des mises à jour.
- **NetworkMonitor** : Bascule automatiquement sur une vue "Hors ligne" native si la connexion est perdue.

### 3. Optimisations iOS
- **UserAgent** : Inclut `netic-ios` pour activer les styles CSS mobiles du site.
- **Viewport** : Configuré pour `viewport-fit=cover` afin d'utiliser toute la surface de l'écran (y compris sous l'encoche).
- **Vibrations** : Support des styles `light`, `medium`, et `heavy`.
