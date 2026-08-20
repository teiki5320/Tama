# Tama sur TestFlight

Méthode retenue : **Xcode Cloud**, comme les autres apps du studio.
Aucune clé API, aucun secret dans le dépôt — Apple parle directement à
GitHub.

Le dépôt est prêt : bundle `com.teiki.tama`, équipe `K597U7X3FZ`, icônes,
portrait uniquement, conformité export déclarée, schéma `Runner` partagé,
et le script d'amorçage Flutter attendu par Xcode Cloud.

## Étapes côté Apple (une seule fois)

### 1. L'identifiant et la fiche — déjà faits

- App ID `com.teiki.tama` enregistré sur developer.apple.com.
- Fiche **Tama TV** créée sur App Store Connect.

Si un jour il faut recommencer pour une autre app : l'identifiant se crée
sur `developer.apple.com` (Certificates, IDs & Profiles → Identifiers →
**+** → App IDs → App, **Explicit**, aucune capability), **avant** la
fiche sur `appstoreconnect.apple.com`, sinon il n'apparaît pas dans le
menu déroulant. Le nom de la fiche est unique dans le monde entier — d'où
« Tama TV » plutôt que « Tama », le nom sous l'icône restant « Tama ».

### 2. Créer le workflow Xcode Cloud — depuis Xcode, sur un Mac

⚠️ **Le premier workflow ne peut pas être créé depuis le web.** L'onglet
Xcode Cloud d'App Store Connect affiche « Créez un processus dans Xcode
pour commencer » et ne propose que le bouton « Ouvrir Xcode ». Une fois le
workflow créé, tout se gère ensuite depuis le web (modification, lancement
de builds) — y compris depuis un iPad.

Sur le Mac, préparer le projet puis ouvrir le **workspace** (pas le
`.xcodeproj`, à cause de CocoaPods) :

```bash
git pull
flutter pub get
# Génère le Podfile, les pods et Generated.xcconfig
flutter build ios --release --config-only --no-codesign
open ios/Runner.xcworkspace
```

Le `ios/Podfile` est produit par cette commande : **le committer** une
fois généré, pour que la configuration des pods soit reproductible.

Dans Xcode : menu **Product → Xcode Cloud → Create Workflow**, puis

1. **Produit** : `Runner` → Next.
2. **Dépôt** : connecter GitHub et autoriser l'accès à `teiki5320/Tama`.
   C'est la seule autorisation à donner, aucune clé à copier.
3. **Branche** : `main`.
4. **Action** : **Archive** · Schéma **Runner** · Configuration
   **Release** · Préparation au déploiement **TestFlight et App Store**.
5. **Post-action** : **TestFlight — tests internes**, en sélectionnant le
   groupe de testeurs créé à l'étape 4 ci-dessous.
6. **Condition de démarrage** : changements de branche sur `main`, ou
   manuel.

Xcode Cloud gère seul les certificats et profils de signature.

### 3. Le script d'amorçage — déjà dans le dépôt

Xcode Cloud ne connaît que Xcode : après le clone il ne trouverait ni le
SDK Flutter, ni `Generated.xcconfig` (ignoré par git), ni les pods. C'est
le rôle de [`ios/ci_scripts/ci_post_clone.sh`](../ios/ci_scripts/ci_post_clone.sh),
exécuté automatiquement après chaque clone. Il installe Flutter et
CocoaPods, puis lance `flutter build ios --config-only`, qui prépare le
projet sans compiler — l'archivage étant le travail de Xcode Cloud.

⚠️ **Ne pas retirer le bit exécutable du fichier** (`chmod +x`), sinon
Xcode Cloud l'ignore silencieusement et l'archivage échoue sur un
`Generated.xcconfig` introuvable.

Le numéro de build vient de `CI_BUILD_NUMBER`, fourni par Xcode Cloud et
incrémenté à chaque exécution : sans cela, tous les builds porteraient le
numéro 1 et App Store Connect refuserait les envois suivants comme
doublons.

### 4. Inviter des testeurs

App Store Connect → Tama TV → **TestFlight** → **Testeurs internes**
(jusqu'à 100, disponibles immédiatement) ou **Testeurs externes**
(jusqu'à 10 000, première soumission relue par Apple, en général < 48 h).

## Variables d'environnement

Le build par défaut tourne en **mode démo** : catalogue local, vidéo de
démonstration, aucun backend requis. C'est voulu pour les premiers essais.

Pour brancher le vrai backend, ajouter les variables dans les réglages du
workflow Xcode Cloud (Environnement → Variables), puis les passer au build
en ajoutant à la fin du script d'amorçage :

```sh
--dart-define=SUPABASE_URL="$SUPABASE_URL" \
--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
--dart-define=BUNNY_STREAM_LIBRARY_ID="$BUNNY_STREAM_LIBRARY_ID" \
--dart-define=BUNNY_STREAM_CDN_HOSTNAME="$BUNNY_STREAM_CDN_HOSTNAME"
```

Cocher **Secret** pour les valeurs sensibles.

## Chemins alternatifs

### Depuis un Mac

```bash
flutter pub get
open ios/Runner.xcworkspace
```

Xcode → « Any iOS Device » → **Product → Archive** → **Distribute App →
TestFlight & App Store**. La signature automatique est déjà configurée.

### GitHub Actions

[`.github/workflows/testflight.yml`](../.github/workflows/testflight.yml)
fait le même travail depuis un runner macOS, mais exige une clé API App
Store Connect et trois secrets — inutile puisque Xcode Cloud est en place.
Il reste utile pour son option **« Essai à blanc »**, qui compile l'app
sans signer ni téléverser et sans aucun secret : pratique pour vérifier
que la chaîne tient après une mise à jour de Flutter ou une nouvelle
dépendance.

L'essai à blanc valide la compilation iOS complète, le schéma Xcode, la
validité d'`ExportOptions.plist`, la présence de l'outil d'envoi Apple et
l'absence de canal alpha sur l'icône 1024×1024 (motif de rejet automatique
côté Apple). Vérifié le 11/08/2026 sur `macos-latest` : au vert en 3 min 20.
