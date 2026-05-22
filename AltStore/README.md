# AltStore Source pour Netic AI

Ce dossier contient le fichier `apps.json` permettant d'ajouter Netic AI comme source personnalisée dans **AltStore** ou **TrollStore**.

## Comment l'ajouter à AltStore ?

1. Assurez-vous d'avoir l'application **AltStore** installée sur votre iPhone.
2. Sur votre iPhone, copiez l'URL brute (Raw) de ce fichier `apps.json` :
   `https://raw.githubusercontent.com/kizYTB/Netic-IOS/main/AltStore/apps.json`
3. Ouvrez **AltStore**, allez dans l'onglet **Sources**.
4. Appuyez sur le **+** en haut à droite.
5. Collez l'URL et validez.
6. L'application **Netic AI** apparaîtra désormais dans AltStore, prête à être installée et mise à jour !

## ⚠️ Important concernant le fichier .ipa

Dans le fichier `apps.json`, le lien de téléchargement (`downloadURL`) pointe actuellement vers les *Releases* GitHub :
`https://github.com/kizYTB/Netic-IOS/releases/latest/download/NeticAI.ipa`

**Pour que cela fonctionne :**
Une fois que Codemagic a généré votre fichier `NeticAI.ipa`, vous devez :
1. Aller sur votre dépôt GitHub.
2. Créer une nouvelle **Release** (Version).
3. Ajouter le fichier `NeticAI.ipa` en pièce jointe de cette release.

Dès que le fichier est en ligne, AltStore pourra le télécharger et l'installer sur votre iPhone.

## Icône sur l'écran d'accueil

Si l'icône reste blanche après installation :

1. **Supprimez** complètement l'app, réinstallez la dernière release GitHub.
2. Dans AltStore (version récente) : onglet **Mes apps** → appui long sur **Netic AI** → **Changer l'icône** → choisir `icon.png` depuis le dépôt.

Les builds récents incluent `Assets.car` + fichiers `AppIcon*.png` dans le `.ipa` (requis pour l'affichage sur l'écran d'accueil).
