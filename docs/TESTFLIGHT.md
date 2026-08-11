# Tama sur TestFlight

Le repo est prêt : bundle `com.teiki.tama`, équipe `K597U7X3FZ`, icônes,
portrait uniquement, conformité export déclarée (pas de chiffrement
spécifique → pas de question à chaque build). Deux chemins possibles.

## Étapes côté Apple (obligatoires, une seule fois, ~10 min)

⚠️ Ces étapes se passent sur **deux sites Apple différents**, et c'est la
source d'erreur n° 1 : l'identifiant se crée sur `developer.apple.com`,
la fiche de l'app sur `appstoreconnect.com`. App Store Connect ne crée
jamais un Bundle ID, il ne fait que lister ceux déjà enregistrés.

### 1. Enregistrer l'identifiant (developer.apple.com)

À faire **avant** de créer la fiche, sinon `com.teiki.tama` n'apparaîtra
pas dans le menu déroulant.

1. Aller sur
   [developer.apple.com/account/resources/identifiers/list](https://developer.apple.com/account/resources/identifiers/list)
   (menu **Certificates, IDs & Profiles** → **Identifiers**).
2. Vérifier en haut à droite que l'équipe sélectionnée est bien celle du
   Team ID **K597U7X3FZ** (si le compte appartient à plusieurs équipes).
3. Cliquer le **+** bleu → **App IDs** → Continue → type **App** → Continue.
4. Remplir :
   - **Description** : `Tama` — champ interne. Apple refuse les accents,
     apostrophes et emoji ici.
   - **Bundle ID** : cocher **Explicit** (surtout pas Wildcard) et saisir
     exactement `com.teiki.tama`, tout en minuscules.
   - **Capabilities** : ne rien cocher. Tama n'utilise ni notifications
     push, ni Sign in with Apple, ni achats intégrés à ce stade.
5. **Continue** → **Register**.

L'identifiant est immédiat, mais App Store Connect peut mettre quelques
minutes à le voir. Si le menu déroulant reste vide, se déconnecter puis
reconnecter d'App Store Connect.

**Si la section « Identifiers » est introuvable** : l'adhésion payante au
[Apple Developer Program](https://developer.apple.com/programs/) (99 $/an)
n'est pas active. Elle est obligatoire pour TestFlight — un compte gratuit
ne permet que d'installer sur ses propres appareils, pendant 7 jours.

### 2. Créer la fiche de l'app (appstoreconnect.apple.com)

[App Store Connect](https://appstoreconnect.apple.com) → **Mes apps** →
**+** → **Nouvelle app** :

- **Plateformes** : iOS
- **Nom** : `Tama` — unique dans le monde entier. S'il est refusé, en
  choisir un autre (`Tama Drama`, `Tama TV`…) : ce nom n'est que celui de
  la fiche, l'app garde « Tama » sous l'icône (`CFBundleDisplayName`).
- **Langue principale** : Français
- **Bundle ID** : `com.teiki.tama` (celui de l'étape 1)
- **SKU** : `tama-ios` — référence interne libre, jamais visible du public.
- **Accès utilisateur** : Accès complet.

### 3. Créer une clé API App Store Connect

Nécessaire seulement pour le chemin CI (chemin B).
Users and Access → **Integrations** → App Store Connect API → **+** :

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
   | `ASC_KEY_CONTENT` | contenu du fichier `.p8` |

   Le `.p8` est un fichier texte : depuis un iPad, l'ouvrir dans Fichiers,
   tout sélectionner, copier, coller dans le secret — de
   `-----BEGIN PRIVATE KEY-----` à `-----END PRIVATE KEY-----` inclus.
   La version encodée (`base64 -i AuthKey_XXX.p8`) est acceptée aussi,
   le workflow reconnaît les deux formes.

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
