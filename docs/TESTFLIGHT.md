# Tama sur TestFlight

Le repo est prêt : bundle `com.teiki.tama`, équipe `K597U7X3FZ`, icônes,
portrait uniquement, conformité export déclarée (pas de chiffrement
spécifique → pas de question à chaque build). Deux chemins possibles.

## Étapes côté Apple (obligatoires, une seule fois, ~10 min)

1. **Créer la fiche de l'app** sur [App Store Connect](https://appstoreconnect.apple.com)
   → Mes apps → **+** → Nouvelle app :
   - Plateforme : iOS · Nom : **Tama** · Langue : Français
   - Bundle ID : **com.teiki.tama** — s'il n'apparaît pas dans la liste,
     l'enregistrer d'abord sur
     [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers)
     (Identifiers → **+** → App IDs → App, aucune capability à cocher).
   - SKU : `tama-ios` (libre, invisible publiquement).

2. **Créer une clé API App Store Connect** (nécessaire seulement pour le
   chemin CI) : Users and Access → **Integrations** → App Store Connect API
   → **+** :
   - Rôle : **App Manager** (requis pour la signature cloud automatique).
   - Télécharger le fichier `.p8` (téléchargeable **une seule fois**),
     noter le **Key ID** et l'**Issuer ID** affichés sur la même page.

## Chemin A — avec un Mac (le plus simple)

```bash
git pull
flutter pub get
open ios/Runner.xcworkspace
```

Dans Xcode : se connecter avec le compte Apple (Settings → Accounts),
sélectionner le device « Any iOS Device », puis **Product → Archive** →
**Distribute App → TestFlight & App Store**. Xcode gère certificats et
profils tout seul (signature automatique déjà configurée).

Pour un vrai build de production, penser aux variables :

```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=BUNNY_STREAM_LIBRARY_ID=... \
  --dart-define=BUNNY_STREAM_CDN_HOSTNAME=...
```

## Chemin B — sans Mac : GitHub Actions

Le workflow [.github/workflows/testflight.yml](../.github/workflows/testflight.yml)
compile, signe (signature cloud automatique) et téléverse depuis un runner
macOS — gratuit sur ce repo public.

1. Sur GitHub : **Settings → Secrets and variables → Actions** → ajouter :

   | Secret | Valeur |
   |---|---|
   | `ASC_KEY_ID` | Key ID de la clé API |
   | `ASC_ISSUER_ID` | Issuer ID de l'équipe |
   | `ASC_KEY_CONTENT` | contenu du `.p8` en base64 : `base64 -i AuthKey_XXX.p8` |

2. Onglet **Actions** → workflow **TestFlight** → **Run workflow**.
3. À la fin (~15-20 min), le build apparaît dans App Store Connect →
   TestFlight (traitement Apple : quelques minutes de plus).

Le numéro de build est automatique (numéro d'exécution du workflow), donc
chaque envoi est accepté sans collision. Premier lancement d'un workflow
signé : il peut échouer si la fiche app (étape Apple n° 1) n'existe pas
encore — la créer puis relancer.

⚠️ Le workflow tel quel compile en **mode démo** (pas de secrets Supabase).
Pour un build branché au backend, ajouter les secrets `SUPABASE_URL`, etc.
et les passer en `--dart-define` dans l'étape « Compilation Flutter » —
à faire quand le backend sera prêt.

## Inviter des testeurs

App Store Connect → TestFlight → **Testeurs internes** (jusqu'à 100,
disponibles immédiatement) ou **Testeurs externes** (jusqu'à 10 000,
première soumission relue par Apple, généralement < 48 h). Chaque testeur
reçoit une invitation par email et installe via l'app TestFlight.
