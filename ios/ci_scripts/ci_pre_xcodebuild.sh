#!/bin/sh
# Script exécuté par Xcode Cloud juste avant `xcodebuild archive`.
#
# Les phases de build de la cible Runner (« Run Script » et « Thin Binary »)
# appellent $FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh, où
# FLUTTER_ROOT vient de ios/Flutter/Generated.xcconfig, écrit par
# ci_post_clone.sh. Si ce fichier manque — ou pointe vers un SDK absent
# parce que l'étape xcodebuild ne partage pas le même $HOME que l'étape
# post-clone — l'archive casse avec un exit 65 difficile à lire.
#
# Ce script vérifie l'invariant et le répare avant de laisser tourner
# xcodebuild.
set -e

PROJECT_DIR="$CI_PRIMARY_REPOSITORY_PATH"
GENERATED="$PROJECT_DIR/ios/Flutter/Generated.xcconfig"

echo "🔎 Vérification de la configuration Flutter avant xcodebuild"
echo "ℹ️  HOME = $HOME"

NEEDS_REGEN=0

if [ ! -f "$GENERATED" ]; then
  echo "⚠️  $GENERATED absent"
  NEEDS_REGEN=1
else
  FLUTTER_ROOT=$(sed -n 's/^FLUTTER_ROOT=//p' "$GENERATED")
  echo "ℹ️  FLUTTER_ROOT = $FLUTTER_ROOT"
  if [ ! -x "$FLUTTER_ROOT/bin/flutter" ]; then
    echo "⚠️  Aucun SDK Flutter exécutable à $FLUTTER_ROOT"
    NEEDS_REGEN=1
  fi
fi

if [ "$NEEDS_REGEN" = "1" ]; then
  echo "🔧 Régénération de la configuration Flutter"
  export PATH="$HOME/flutter/bin:$PATH"
  cd "$PROJECT_DIR"
  flutter pub get
  flutter build ios \
    --release \
    --config-only \
    --no-codesign \
    --build-number="${CI_BUILD_NUMBER:-1}"
  cat "$GENERATED"
else
  echo "✅ Configuration Flutter cohérente"
fi
