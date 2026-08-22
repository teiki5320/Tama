#!/bin/sh
# Sourcé par ci_post_clone.sh et ci_pre_xcodebuild.sh — jamais lancé seul.
#
# Un seul endroit où la liste des --dart-define est écrite. Les deux scripts
# appellent `flutter build ios --config-only`, et c'est cette commande qui grave
# les valeurs dans ios/Flutter/Generated.xcconfig (clé DART_DEFINES, encodée en
# base64) ; l'archive les y relit. Si les deux listes divergeaient, la
# régénération d'avant-archive effacerait les clés posées après le clone et
# l'app repartirait en mode démo — sans qu'aucune étape n'échoue.

# ----------------------------------------------------------------------------
# Bunny Stream : ces valeurs ne sont pas des secrets, elles figurent dans les
# URLs que l'app appelle (cf. docs/BUNNY.md). Les inscrire ici évite deux
# variables à saisir et une panne muette de plus. Une variable d'environnement
# du processus Xcode Cloud les remplace le jour où la bibliothèque change.
# ----------------------------------------------------------------------------
BUNNY_STREAM_LIBRARY_ID="${BUNNY_STREAM_LIBRARY_ID:-734067}"
BUNNY_STREAM_CDN_HOSTNAME="${BUNNY_STREAM_CDN_HOSTNAME:-vz-c110e438-e92.b-cdn.net}"

# ----------------------------------------------------------------------------
# Les clés Supabase, elles, n'entrent pas dans le dépôt : elles viennent des
# variables d'environnement du processus Xcode Cloud.
#
# Sans elles, tout compile et tout s'archive — et l'app livrée tourne en mode
# démo sur des données locales, sans rien mesurer. C'est exactement la panne
# silencieuse qu'on refuse : autant échouer ici, où le log est lisible.
# ----------------------------------------------------------------------------
tama_require_env() {
  manquantes=""
  for nom in SUPABASE_URL SUPABASE_ANON_KEY; do
    eval "valeur=\$$nom"
    [ -n "$valeur" ] || manquantes="$manquantes $nom"
  done
  if [ -n "$manquantes" ]; then
    echo "❌ Variables absentes du processus Xcode Cloud :$manquantes" >&2
    echo "   App Store Connect → Xcode Cloud → Gérer les processus →" >&2
    echo "   processus de Tama → Environnement → Variables d'environnement." >&2
    return 1
  fi
  echo "✅ Clés Supabase présentes"
  echo "ℹ️  BUNNY_STREAM_CDN_HOSTNAME = $BUNNY_STREAM_CDN_HOSTNAME"
}

# Écrit toute la configuration Xcode du mode Release sans compiler.
#
# --build-number : sans lui, tous les builds porteraient le numéro 1 et
# App Store Connect refuserait les envois suivants comme doublons.
tama_flutter_config_only() {
  flutter build ios \
    --release \
    --config-only \
    --no-codesign \
    --build-number="${CI_BUILD_NUMBER:-1}" \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=BUNNY_STREAM_LIBRARY_ID="$BUNNY_STREAM_LIBRARY_ID" \
    --dart-define=BUNNY_STREAM_CDN_HOSTNAME="$BUNNY_STREAM_CDN_HOSTNAME"
}
