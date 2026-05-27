# Netic iOS App

Ce répertoire contient le code source de l'application iOS native pour Netic. 
L'application est construite avec **SwiftUI** et utilise un **WKWebView** optimisé pour afficher l'application web Netic.

## Structure du projet

- `Sources/App/NeticApp.swift` : Point d'entrée de l'application.
- `Sources/Views/WebView.swift` : Wrapper SwiftUI pour WKWebView avec support du bridge JS.
- `Sources/Views/ContentView.swift` : Vue principale avec écran de chargement.
- `Info.plist` : Configuration des permissions (Caméra, Micro, Réseau).

## Installation et Compilation

1. Ouvrez Xcode.
2. Créez un nouveau projet : **File > New > Project...**
3. Sélectionnez **iOS > App**.
4. Nommez le projet `Netic`, Interface : **SwiftUI**, Language : **Swift**.
5. Une fois le projet créé, remplacez les fichiers générés par ceux de ce répertoire :
   - Remplacez `NeticApp.swift` par le nôtre.
   - Ajoutez `WebView.swift`, `ContentView.swift`, `LoadingView.swift`.
   - Copiez le dossier `Assets.xcassets` dans votre projet Xcode pour avoir les logos et icônes officiels.
   - Configurez le `Bundle Identifier` sur `fr.neticai.app`.
6. Dans l'onglet **General** de votre Target :
   - Sous **App Icon and Launch Images**, assurez-vous que `AppIcon` est sélectionné.
7. Dans les paramètres du projet (Target > Info), assurez-vous d'ajouter les clés de permission pour la Caméra et le Micro présentes dans notre `Info.plist`.

## Build Automatisé (Codemagic)

Le fichier `codemagic.yaml` est présent à la racine pour automatiser la génération du fichier `.ipa`.

1. Connectez votre dépôt GitHub à **Codemagic.io**.
2. L'application sera automatiquement détectée.
3. Configurez les variables d'environnement pour le **Code Signing** (Certificats et Profils de Provisioning Apple) dans l'interface Codemagic.
4. Lancez le build via le workflow `ios-workflow`.

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
