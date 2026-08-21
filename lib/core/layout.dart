import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Classes de largeur d'écran. Le téléphone reste la cible du produit : les
/// paliers supérieurs élargissent la mise en page sans changer la hiérarchie
/// ni le nombre d'écrans.
enum TamaWidth { phone, tablet, wide }

/// Paliers et mesures dépendant de la largeur disponible. Tout ce qui varie
/// d'un format à l'autre se décide ici — les écrans n'écrivent pas de
/// dimension eux-mêmes.
abstract final class TamaLayout {
  static const double _tablet = 600;
  static const double _wide = 1000;

  static TamaWidth of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= _wide) return TamaWidth.wide;
    if (width >= _tablet) return TamaWidth.tablet;
    return TamaWidth.phone;
  }

  /// Largeur d'une affiche dans un rail horizontal.
  static double posterWidth(BuildContext context) => switch (of(context)) {
        TamaWidth.phone => 96,
        TamaWidth.tablet => 132,
        TamaWidth.wide => 158,
      };

  /// Hauteur d'un rail : l'affiche est en 9:14, plus la marge de la jauge.
  static double railHeight(BuildContext context) =>
      posterWidth(context) * 14 / 9 + 4;

  /// Hauteur de la bannière d'accueil. Sur téléphone elle occupe l'écran ;
  /// au-delà, elle passe en format paysage et ne dépasse jamais les deux
  /// tiers de la hauteur, pour que le premier rail reste amorcé.
  static double bannerHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ratio = of(context) == TamaWidth.phone ? 5 / 4 : 9 / 16;
    return math.min(size.width * ratio, size.height * 0.66);
  }

  /// Hauteur de la cover en tête de fiche série.
  static double coverHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return math.min(
      of(context) == TamaWidth.phone ? 340 : size.width * 0.42,
      size.height * 0.55,
    );
  }

  /// Colonnes de la grille des favoris.
  static int favoriteColumns(BuildContext context) => switch (of(context)) {
        TamaWidth.phone => 3,
        TamaWidth.tablet => 5,
        TamaWidth.wide => 7,
      };

  /// Colonnes de la grille des épisodes d'une série.
  static int episodeColumns(BuildContext context) => switch (of(context)) {
        TamaWidth.phone => 5,
        TamaWidth.tablet => 8,
        TamaWidth.wide => 10,
      };

  /// Largeur maximale d'un bloc de texte suivi. Au-delà, les lignes
  /// deviennent trop longues pour être lues confortablement.
  static const double readableWidth = 640;

  /// Corps du titre de la bannière d'accueil. Une affiche se lit de loin :
  /// sur un grand écran, elle grandit avec lui.
  static double posterFontSize(BuildContext context) => switch (of(context)) {
        TamaWidth.phone => 40,
        TamaWidth.tablet => 58,
        TamaWidth.wide => 68,
      };

  /// Corps du titre d'une fiche série, même principe.
  static double titleFontSize(BuildContext context) => switch (of(context)) {
        TamaWidth.phone => 32,
        TamaWidth.tablet => 42,
        TamaWidth.wide => 48,
      };

  /// Largeur maximale de la scène du lecteur. La vidéo est verticale : sur
  /// un grand écran elle est cadrée dans une colonne centrée plutôt que
  /// recadrée en plein cadre, ce qui n'en montrerait qu'une bande.
  static double stageWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (of(context) == TamaWidth.phone) return size.width;
    return math.min(size.width, size.height * 9 / 16);
  }
}
