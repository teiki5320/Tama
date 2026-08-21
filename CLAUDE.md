# Travailler sur Tama

Tama est une app mobile de streaming de micro-dramas verticaux (~1 min),
spécialisée dans les dramas africains francophones, produite par le studio
du propriétaire du dépôt. MVP sans monétisation : l'unique objectif est de
mesurer la rétention et le taux de complétion (vue SQL `v_retention`).

- Bundle ID : `com.teiki.tama` · Apple Team ID : `K597U7X3FZ`
- Fiche App Store : **Tama TV** (le nom « Tama » était déjà pris ; sous
  l'icône, l'app s'appelle bien « Tama »).

## Comment on travaille

- **Réponds toujours en français**, y compris dans le raisonnement visible.
- **Numérote chaque choix laissé au développeur.** Trois questions dans un
  message doivent pouvoir se répondre « 1 oui, 2 non, 3 plus tard ».
- **Tout se fait sur `main`, directement. On ne crée pas de branche.**
- **Demande plutôt que de décider seul** d'un changement de cap, et ne
  lance pas de longue exploration sans accord — les jetons sont payants.
  Ne propose pas d'alternative à ce qui est déjà tranché ci-dessous.
- **Ne laisse aucune trace de tes erreurs.** Corrige proprement plutôt que
  d'empiler un correctif sur une bêtise.
- **Vérifie avant d'affirmer.** App Store Connect change plusieurs fois
  par an : consulte la documentation d'Apple ou demande une capture,
  plutôt que de guider de mémoire.
- **Avant tout commit** : `flutter analyze` et `flutter test` doivent
  passer.
- **Aucun test ne couvre la compilation iOS.** `analyze`, les tests et
  même un build Android peuvent tous passer sur un projet qui n'archive
  pas. Toucher à `ios/`, au `Podfile` ou à une dépendance native, c'est
  s'engager à surveiller le build Xcode Cloud qui suit.

## Distribution — la méthode du studio

**Xcode Cloud, toujours.** Aucun secret dans le dépôt. Ne propose ni
GitHub Actions, ni Codemagic, ni aperçu web, ni APK : la question est
tranchée.

Amorçage Flutter dans `ios/ci_scripts/` — `ci_post_clone.sh` (installe le
SDK, les pods, écrit `Generated.xcconfig`) et `ci_pre_xcodebuild.sh`
(vérifie et répare `FLUTTER_ROOT` avant l'archive). **Les deux fichiers
doivent rester exécutables** (`chmod +x`), sinon Xcode Cloud les ignore
en silence et l'archive échoue sur un exit 65 illisible.

### Ranger les apps Flutter dans Xcode Cloud

Un « produit » Xcode Cloud est identifié par **le nom du schéma
archivable**, pas par l'identifiant d'app ni par le dépôt. Xcode dresse la
liste avec `xcodebuild -describeAllArchivableProducts` ; tout projet
Flutter y répond `Runner`. D'où la collision : App Store Connect retrouve
un produit `Runner` déjà connu et le réutilise, pour une autre app.

**Avant de configurer Xcode Cloud sur une app Flutter, lui donner un
schéma à son nom** (dans Xcode : Product → Scheme → Manage Schemes… →
dupliquer `Runner`, le renommer `TrainCosy`, cocher **Shared**). Trois
conditions à vérifier :

- le schéma est **partagé** — sinon Xcode Cloud ne le voit pas ;
- son action **Archive** est cochée ;
- `Runner` reste en place : `flutter build ios` s'en sert.

Puis Integrate → Create Workflow… et **choisir le schéma au nom de
l'app**. Aucun produit ne portant ce nom, App Store Connect en crée un
neuf : plus rien à voler.

Tama a le sien : `TamaTV`, dans
`ios/Runner.xcodeproj/xcshareddata/xcschemes/`.

**Sur une app dont le produit fonctionne déjà** (Erea) : ne plus jamais
lancer Create Workflow… depuis Xcode. Tout se règle depuis App Store
Connect → Xcode Cloud → Gérer les processus. C'est cette commande, et elle
seule, qui a déclenché le vol.

**Après chaque configuration**, ouvrir la page Xcode Cloud des autres apps
et vérifier qu'elles ont toujours la leur, avec le bon nom de produit.

## Les pièges déjà payés

- ⚠️ **Configurer Xcode Cloud pour une app Flutter peut voler le produit
  d'une autre app Flutter.** Tous les projets Flutter ont un schéma et un
  espace de travail nommés `Runner` : l'assistant Xcode reconnaît « un
  projet Runner déjà connu » et range le nouveau processus dans le produit
  existant, au lieu d'en créer un neuf — sans vérifier que l'identifiant
  d'app diffère. Le 21/08/2026, configurer Tama a renommé le produit
  d'Erea en « tama » et l'a repointé vers Tama TV : la page Xcode Cloud
  d'Erea s'est vidée et son intégration continue s'est arrêtée.
  **Symptômes** : la page Xcode Cloud de l'ancienne app est vide ; les deux
  processus apparaissent sous la nouvelle app ; les numéros de build se
  suivent d'une app à l'autre (Erea 118 → Tama 119) ; le processus de la
  nouvelle app affiche « Primary Repository Not Found ».
  **Réparation qui a fonctionné** (21/08/2026, dans cet ordre) :
  1. supprimer le processus de la nouvelle app — nécessaire mais **pas
     suffisant**, le produit reste rattaché à la mauvaise app ;
  2. ouvrir le projet de l'app **volée** dans Xcode, Integrate → Create
     Workflow…, et confirmer **son** app à l'écran « Confirm App ». Xcode
     crée alors un produit neuf, correctement rattaché ;
  3. supprimer l'ancien processus resté dans le produit usurpateur, sinon
     il compilerait le code de l'app volée sous la mauvaise app ;
  4. **remettre le compteur de builds** : un produit neuf repart à 1, donc
     en dessous des builds déjà envoyés, et Apple refuserait les suivants.
     Xcode Cloud → Réglages → **Numéro du build**. Le champ est le numéro
     du *prochain* build : il doit être **supérieur** au dernier existant
     (Erea était à 118 → réglé sur 119).
  **Prévention** : voir « Ranger les apps Flutter dans Xcode Cloud »
  ci-dessous — à appliquer avant de configurer Train Cosy et Drama.
- **Xcode Cloud, action *Archiver*** : la préparation de la distribution
  doit rester sur **« App Store Connect »**. Sur « TestFlight (tests
  internes uniquement) », les builds n'apparaissent jamais dans la liste
  de sélection d'une version. **C'est le premier réglage à vérifier quand
  plus rien n'arrive dans TestFlight** — le 21/08/2026 il a coûté une
  fausse piste (« le processus ne connaît pas le dépôt ») et une
  recréation de processus qui aurait à nouveau volé le produit d'Erea.
- **La version de `pubspec.yaml` doit être identique** à celle saisie dans
  App Store Connect, sinon le build est non sélectionnable.
- **Swift Package Manager doit rester désactivé** : les stables récentes
  l'activent par défaut, podhelper saute alors les plugins compatibles et
  l'archive casse sur « Module 'shared_preferences_foundation' not found ».
  `ci_post_clone.sh` force le mode CocoaPods, ne pas retirer cette ligne.
- **Les mots-clés App Store se comptent en octets**, pas en caractères :
  chaque accent en vaut deux.
- **Flutter ne descend pas dans les sous-dossiers d'assets** : chaque
  sous-dossier se déclare à part dans `pubspec.yaml`.
- ⚠️ Chaque poussée sur `main` déclenche un build Xcode Cloud, sans filtre
  de fichiers — même pour un document. Groupe les commits quand c'est
  possible.

## État actuel (ne pas refaire)

- **Base Supabase** : migration complète dans `supabase/migrations/`
  (6 tables, RLS testée, vue `v_retention`), seed de dev dans
  `supabase/seed.sql`. Testée sur Postgres 16. **Pas encore appliquée sur
  le projet Supabase réel.**
- **App Flutter complète** : accueil (bannière, rail « Reprendre », rails
  par genre), fiche série, player vertical (swipe, préchargement du seul
  épisode suivant, enchaînement auto, reprise, sauvegarde 5 s), ma liste,
  réglages, auth Supabase, analytics en lots de 10 s.
- **Mode démo intégré** : sans `--dart-define` Supabase, l'app tourne sur
  des données locales (`lib/repositories/mock_data.dart`). Toute nouvelle
  fonctionnalité DOIT continuer à fonctionner en mode démo.
- **iOS prêt à archiver** : icônes (sans canal alpha), Team ID posé,
  schéma `Runner` partagé, portrait uniquement, conformité export
  déclarée, scripts Xcode Cloud en place.

## Stack et architecture

Flutter + Riverpod + go_router + Supabase + Bunny Stream (HLS).
Pas de backend custom. Structure : `lib/core` (thème, env, router),
`lib/models`, `lib/repositories` (une classe par table, impl. Supabase +
impl. démo), `lib/providers`, `lib/features/<écran>`, `lib/services`
(analytics, bunny, connectivité).

## Règles de code non négociables

1. **Aucune couleur, rayon ou taille de police en dur** : tout passe par
   les jetons de `lib/core/theme.dart` (`TamaColors`, `TamaText`,
   `TamaSpacing`, `TamaRadius`). Accent doré = actions et états actifs
   uniquement, jamais en aplat.
2. **Trois états par écran** (chargement / vide / erreur) via
   `lib/core/widgets/async_view.dart`. Pas d'écran blanc, pas d'objet
   invisible mais cliquable.
3. **Réseau dégradé d'abord** : l'app doit rester utilisable en 3G.
   Jamais plus d'un épisode préchargé ; le mode données réduites coupe
   tout préchargement.
4. **Analytics d'abord** : tout nouveau comportement de lecture doit
   émettre les événements adéquats via `AnalyticsService` (batch 10 s,
   `.insert()` sans `.select()` — la lecture de `analytics_events` est
   bloquée par RLS).
5. **Zéro friction** : rien ne doit exiger un compte avant le premier
   favori. La progression anonyme vit en local et se synchronise à la
   connexion.
6. **Commentaires en français**, identifiants en anglais.

## Variables d'environnement (--dart-define)

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `BUNNY_STREAM_LIBRARY_ID`,
`BUNNY_STREAM_CDN_HOSTNAME` — sans les deux premières : mode démo.

## Où trouver quoi

| Fichier | Contenu |
|---|---|
| `docs/TESTFLIGHT.md` | la procédure Xcode Cloud, pas à pas |
| `supabase/migrations/` | le schéma, à coller dans Supabase |
| `lib/core/theme.dart` | tous les jetons de design |

## Backlog connu (phase suivante, sur demande uniquement)

- Brancher le vrai backend (exécuter la migration dans Supabase, charger
  covers 9:16 WebP et identifiants vidéo Bunny réels).
- Icônes adaptatives Android, splash iOS avec logo.
- Phase 2 (seulement si les métriques tiennent) : monétisation.
