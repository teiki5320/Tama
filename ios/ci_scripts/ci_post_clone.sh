#!/bin/sh
# ============================================================================
# Amorçage Xcode Cloud pour Tama (projet Flutter).
#
# Xcode Cloud ne connaît que Xcode : après le clone, il ne trouverait ni le
# SDK Flutter, ni Generated.xcconfig (ignoré par git), ni les pods. Ce script
# prépare tout cela avant que Xcode Cloud lance l'archivage.
#
# Emplacement imposé par Apple : à côté du projet Xcode, donc
# ios/ci_scripts/ci_post_clone.sh — et le fichier doit être exécutable.
# ============================================================================
set -e

FLUTTER_CHANNEL="stable"
FLUTTER_HOME="$HOME/flutter"

# Racine du dépôt : fournie par Xcode Cloud, déduite sinon (exécution locale).
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"

echo "→ Installation de Flutter ($FLUTTER_CHANNEL)"
git clone https://github.com/flutter/flutter.git \
  --depth 1 -b "$FLUTTER_CHANNEL" "$FLUTTER_HOME"
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --version

# Les images Xcode Cloud n'embarquent pas toujours CocoaPods.
if ! command -v pod > /dev/null 2>&1; then
  echo "→ Installation de CocoaPods"
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

echo "→ Artefacts iOS"
flutter precache --ios

cd "$REPO_ROOT"

echo "→ Dépendances Dart"
flutter pub get

# --config-only : génère Generated.xcconfig et installe les pods SANS
# compiler — l'archivage est le travail de Xcode Cloud, inutile de le
# faire deux fois.
#
# --build-number : sans cela, chaque build porterait le numéro 1 et App
# Store Connect refuserait les envois suivants comme doublons. Xcode Cloud
# fournit un compteur qui s'incrémente à chaque exécution.
echo "→ Configuration iOS (Generated.xcconfig + pods)"
flutter build ios \
  --release \
  --config-only \
  --no-codesign \
  --build-number="${CI_BUILD_NUMBER:-1}"

echo "✓ Amorçage terminé — Xcode Cloud peut archiver."
