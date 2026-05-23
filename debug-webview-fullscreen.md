[OPEN]

# Debug Session: webview-fullscreen

## Problematique
- Comportement actuel: la page de connexion affiche de grosses bandes noires en haut et en bas au lieu d'occuper tout l'ecran.
- Comportement attendu: la `WKWebView` et la page chargee doivent occuper 100 % de l'ecran, y compris pendant le login Jtheberg.

## Reproduction
1. Lancer l'application iOS.
2. Aller sur le flux de connexion Jtheberg.
3. Observer l'ecran de login avec bandes noires en haut et en bas.

## Notes Initiales
- Les tentatives precedentes de correction purement statique n'ont pas resolu le probleme.
- Cette session collecte des preuves runtime avant toute correction supplementaire.

## Hypotheses
| ID | Hypothese | Probabilite | Effort | Signal attendu |
|----|-----------|-------------|--------|----------------|
| A | La `WKWebView` n'a pas la bonne taille native | Haute | Faible | `bounds.height` ou `frame.height` inferieur a la hauteur ecran |
| B | iOS reapplique des insets au `scrollView` | Haute | Faible | `adjustedContentInset.top/bottom` non nuls |
| C | Le viewport ou la hauteur DOM de la page OAuth est plus petite que l'ecran | Haute | Faible | `innerHeight`, `clientHeight` ou `scrollHeight` incoherents |
| D | Le login passe par une popup / autre contexte `WKWebView` | Moyenne | Faible | `createWebViewWith` appele pendant le flux |
| E | Le rendu visible ne vient pas de la page principale mais d'un overlay / contexte de navigation | Moyenne | Faible | navigation correcte mais dimensions natives et DOM normales |

## Instrumentation
- `A` dans `WebView.makeUIView`: creation native et insets initiaux.
- `B` dans `WebView.didFinish`: dimensions natives, safe area, content insets, content size.
- `C` dans `WebView.didFinish` via JavaScript: viewport et dimensions DOM effectives.
- `D` dans `createWebViewWith`: popup / target frame.
- `E` dans `decidePolicyFor`: URL effectivement chargee et type de frame.

## Ajustement Collecte
- Le premier endpoint `127.0.0.1` ne pouvait pas etre joint depuis l'iPhone.
- L'instrumentation utilise maintenant l'endpoint LAN `http://192.168.1.44:7777/event`.
