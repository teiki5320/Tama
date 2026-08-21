# Tama sur TestFlight

## Configuration en place (à reproduire à l'identique en cas de perte)

Processus Xcode Cloud **« Tama TV »**, créé le 21 août 2026.

| Réglage | Valeur |
|---|---|
| Produit Xcode Cloud | `tama` |
| Dépôt principal | `https://github.com/teiki5320/Tama.git` |
| Projet ou espace de travail | `ios/Runner.xcworkspace` |
| Condition de démarrage | Modifications de branches · branche `main` · toute modification de fichier · annulation automatique activée |
| Action | Archiver · plateforme iOS · schéma `Runner` · configuration Release |
| Préparation de la distribution | **App Store Connect** |
| Actions postérieures | aucune |
| Environnement | Xcode « Latest Release » · macOS « Latest Release » |
| Variables d'environnement | aucune (l'app tourne en mode démo) |

**État au 21 août 2026 : en service.** Chaque poussée sur `main` déclenche
un build, qui arrive dans TestFlight. Le tableau ci-dessus est la
référence des réglages à reproduire en cas de perte — la ligne
**Préparation de la distribution** en particulier.

### L'incident du 21 août 2026

En créant ce processus depuis Xcode, l'assistant a rangé la recette de
Tama dans le produit Xcode Cloud **d'Erea** au lieu d'en créer un neuf,
l'a renommé « tama » et l'a repointé vers Tama TV. Conséquences observées :

- la page Xcode Cloud d'Erea s'est vidée, son intégration continue arrêtée ;
- les deux processus figuraient sous Tama TV ;
- les compteurs de build se suivaient (Erea 118 → Tama 119) ;
- le processus de Tama affichait « Primary Repository Not Found », le
  produit ne connaissant que le dépôt d'Erea.

**La cause** : un produit Xcode Cloud est identifié par le **nom du schéma
archivable**. Xcode dresse la liste des produits configurables avec
`xcodebuild -describeAllArchivableProducts` ; tout projet Flutter y répond
`Runner`. App Store Connect a donc retrouvé un produit `Runner` déjà connu
et l'a réutilisé, sans tenir compte de l'identifiant d'app pourtant
différent.

**La réparation**, appliquée le 21 août, en trois temps :

1. Supprimer le processus « Tama TV » du produit usurpateur. Nécessaire,
   mais **insuffisant** : le produit restait rattaché à l'app Tama TV.
2. Ouvrir `erea_flutter/ios/Runner.xcworkspace` dans Xcode, puis
   Integrate → **Create Workflow…**, en confirmant **Erea** à l'écran
   « Confirm App ». Xcode a alors créé un produit neuf, `erea`,
   correctement rattaché — c'est cette étape qui a tout débloqué.
3. Supprimer « Workflow erea », resté dans le produit `tama` : il aurait
   compilé le code d'Erea sous l'app Tama TV.

**État final** : chaque app a son produit et son processus. Erea compile
sous `erea`, Tama TV sous `tama`, et les deux livrent sur TestFlight.

### ⚠️ Numéro de build après une recréation de produit

Le build 119 de Tama porte ce numéro parce qu'il a hérité du compteur
d'Erea pendant la mésaventure. Un produit Xcode Cloud neuf repart à 1,
donc **sous** 119 : Apple refuserait les builds suivants.

Après toute recréation d'un produit : Xcode Cloud → Réglages → **Numéro
du build** → régler le numéro du *prochain* build **au-dessus** du dernier
déjà envoyé (120 au minimum pour Tama, 119 l'ayant été pour Erea).

### Aucun build n'arrive ? Regarder l'action Archiver d'abord

Le 21 août, plus rien n'est remonté dans TestFlight après plusieurs
poussées. La cause n'était ni le dépôt, ni le produit : la **préparation
de la distribution** de l'action Archiver avait été passée sur
« TestFlight (tests internes uniquement) ». Elle doit rester sur **« App
Store Connect »**.

C'est le premier réglage à vérifier — avant de toucher au processus, et
surtout avant de le recréer, geste qui a déjà volé le produit d'Erea.

### Si un jour il faut recréer le processus

Le dépôt porte un schéma **`TamaTV`**, partagé et archivable
(`ios/Runner.xcodeproj/xcshareddata/xcschemes/TamaTV.xcscheme`), copie
conforme de `Runner`. Il existe pour une seule raison : aucun autre projet
du studio n'expose de produit portant ce nom, donc App Store Connect n'a
rien à réutiliser et crée un produit neuf. `Runner` reste en place,
`flutter build ios` s'en sert.

Sur le Mac, dans l'ordre :

1. `git pull` dans le dépôt Tama, pour récupérer le schéma.
2. Ouvrir `ios/Runner.xcworkspace` dans Xcode — **et fermer les autres
   projets Flutter**, pour ne pas laisser l'assistant piocher ailleurs.
3. Integrate → **Create Workflow…** → à l'écran de choix du produit,
   prendre **`TamaTV`**, jamais `Runner`.
4. Écran « Confirm App » : vérifier que c'est bien **Tama TV**, pas une
   autre app du studio. C'est le dernier point d'arrêt avant le vol.
5. Régler l'action **Archiver** comme dans le tableau en tête de page :
   configuration Release, préparation de la distribution sur **App Store
   Connect**, condition de démarrage sur la branche `main`.
6. Xcode Cloud → Réglages → **Numéro du build** → mettre le numéro du
   prochain build au-dessus du dernier envoyé : un produit neuf repart
   à 1, donc sous les builds déjà déposés.
7. Ouvrir la page Xcode Cloud d'**Erea** et vérifier qu'elle a toujours
   son produit `erea` et son processus.

Pour Train Cosy et Drama, appliquer la même parade avant toute
configuration : voir « Ranger les apps Flutter dans Xcode Cloud » dans
`CLAUDE.md`.


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

Dans Xcode : menu **Integrate → Create Workflow** (et non « Product », qui
ne contient rien de tel), puis

1. **Produit** : `Runner` → Next.
2. **Dépôt** : connecter GitHub et autoriser l'accès à `teiki5320/Tama`.
   C'est la seule autorisation à donner, aucune clé à copier.
3. **Branche** : `main`.
4. **Action** : **Archive** · Schéma **Runner** · Configuration
   **Release** · Préparation de la distribution : **App Store Connect**.

   ⚠️ **Surtout pas « TestFlight (tests internes uniquement) »** : avec ce
   réglage, les builds n'apparaissent jamais dans la liste de sélection
   d'une version. Piège déjà payé sur une autre app du studio.
5. **Condition de démarrage** : **Changements de branche**, branche
   `main`. C'est ce réglage qui fait qu'une poussée sur `main` lance un
   build toute seule.

Xcode Cloud gère seul les certificats et profils de signature.

### 3. Les scripts d'amorçage — déjà dans le dépôt

Xcode Cloud ne connaît que Xcode : après le clone il ne trouverait ni le
SDK Flutter, ni `Generated.xcconfig` (ignoré par git), ni les pods. Deux
scripts s'en chargent, calqués sur ceux d'Erea :

- [`ios/ci_scripts/ci_post_clone.sh`](../ios/ci_scripts/ci_post_clone.sh) —
  installe Flutter (avec réessais, le réseau des runners lâche), force le
  mode CocoaPods, lance `flutter build ios --config-only` puis
  `pod install --repo-update`, et vérifie que `Generated.xcconfig` existe.
- [`ios/ci_scripts/ci_pre_xcodebuild.sh`](../ios/ci_scripts/ci_pre_xcodebuild.sh) —
  vérifie juste avant l'archive que `FLUTTER_ROOT` pointe vers un SDK
  réellement présent, et régénère la configuration sinon.

⚠️ **Ne pas retirer le bit exécutable** (`chmod +x`) : Xcode Cloud ignore
alors les scripts en silence et l'archive échoue sur un exit 65 illisible.

⚠️ **Ne pas retirer `flutter config --no-enable-swift-package-manager`** :
les stables récentes activent SwiftPM par défaut, `pod install` saute
alors les plugins compatibles et l'archive casse sur « Module
'shared_preferences_foundation' not found ». Tama utilise
`shared_preferences`.

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
