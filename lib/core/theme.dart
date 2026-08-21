import 'package:flutter/material.dart';

/// Jetons de design Tama — direction « affiche peinte ».
///
/// Le vocabulaire est celui des affiches de cinéma peintes à la main et des
/// enseignes de maquis : lettres énormes, aplats saturés, couleur assumée.
/// Règle du projet : AUCUNE couleur, rayon ou taille de police en dur
/// ailleurs dans le code — tout est centralisé ici.
abstract final class TamaColors {
  /// Fond général : une terre brûlée, pas un noir bleuté de streaming.
  static const Color background = Color(0xFF140C0B);

  /// Surfaces : cartes, feuilles, barres.
  static const Color surface = Color(0xFF1F1412);

  /// Surface élevée (états actifs, champs).
  static const Color surfaceHigh = Color(0xFF2A1B18);

  /// Encre : un crème, jamais un blanc pur.
  static const Color text = Color(0xFFFBF3E4);

  /// Texte atténué (métadonnées, légendes).
  static const Color textMuted = Color(0x9EFBF3E4);

  /// Texte effacé (repères, unités).
  static const Color textFaint = Color(0x59FBF3E4);

  // ---------------------------------------------------------------------
  // Les accents. Un genre, une couleur : le genre se lit avant le titre.
  // ---------------------------------------------------------------------

  /// Accent principal de la marque — vengeance.
  static const Color vermillon = Color(0xFFE8452C);
  static const Color rose = Color(0xFFD6407E);
  static const Color indigo = Color(0xFF2E4B9B);
  static const Color jaune = Color(0xFFF5B721);
  static const Color emeraude = Color(0xFF1B8A62);

  /// Accent par défaut, utilisé hors contexte de genre.
  static const Color accent = vermillon;

  /// Accent adouci (fonds d'état actif).
  static const Color accentSoft = Color(0x24E8452C);

  /// Voile sombre derrière les overlays du player.
  static const Color scrim = Color(0xC7140C0B);

  /// Piste inactive (barres de progression, séparateurs).
  static const Color track = Color(0x26FBF3E4);

  /// Couleur d'erreur.
  static const Color error = Color(0xFFE8452C);

  /// Couleur d'un genre. Le rapprochement est volontairement tolérant :
  /// le catalogue peut nommer un genre librement.
  static Color forGenre(String? genre) {
    final g = (genre ?? '').toLowerCase();
    if (g.contains('vengeance')) return vermillon;
    if (g.contains('romance') || g.contains('amour')) return rose;
    if (g.contains('thriller') || g.contains('polar')) return indigo;
    if (g.contains('drame')) return emeraude;
    return vermillon;
  }

  /// Dégradé d'affiche pour une série sans visuel : deux tons dérivés de la
  /// couleur du genre. Tant qu'il n'y a pas de cover, la vignette est une
  /// affiche typographique — l'absence devient un parti pris.
  static List<Color> posterGradient(String? genre, String seed) {
    final base = forGenre(genre);
    final hsl = HSLColor.fromColor(base);
    // Le hachage du titre décale légèrement la teinte : deux séries du même
    // genre ne donnent pas exactement la même affiche.
    final shift = (seed.hashCode.abs() % 14) - 7;
    final haut = hsl
        .withHue((hsl.hue + shift) % 360)
        .withSaturation((hsl.saturation * 0.82).clamp(0.0, 1.0))
        .withLightness(0.26)
        .toColor();
    final bas = hsl
        .withHue((hsl.hue + shift) % 360)
        .withSaturation((hsl.saturation * 0.62).clamp(0.0, 1.0))
        .withLightness(0.07)
        .toColor();
    return [haut, bas];
  }
}

/// Rayons d'arrondi. L'affiche est franche : presque pas d'arrondi.
abstract final class TamaRadius {
  /// Vignettes et cartes.
  static const double card = 4;

  /// Boutons et pastilles.
  static const double chip = 2;

  /// Feuilles modales.
  static const double sheet = 16;
}

/// Échelle d'espacement.
abstract final class TamaSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Dégagement à réserver en bas des écrans à barre de navigation, pour que
  /// le dernier bloc ne finisse pas caché dessous.
  static const double navBar = 96;
}

/// Familles de polices embarquées (voir pubspec.yaml).
abstract final class TamaFonts {
  /// Titres : Anton, tracée comme une enseigne.
  static const String title = 'Anton';

  /// Texte courant.
  static const String body = 'Archivo';
}

/// Styles de texte.
abstract final class TamaText {
  /// Titre d'affiche : énorme, capitales, interlignage serré.
  static const TextStyle poster = TextStyle(
    fontFamily: TamaFonts.title,
    fontSize: 40,
    height: 0.86,
    letterSpacing: 0.2,
    color: TamaColors.text,
  );

  static const TextStyle titleXL = TextStyle(
    fontFamily: TamaFonts.title,
    fontSize: 32,
    height: 0.9,
    letterSpacing: 0.2,
    color: TamaColors.text,
  );

  static const TextStyle titleL = TextStyle(
    fontFamily: TamaFonts.title,
    fontSize: 22,
    height: 0.95,
    letterSpacing: 0.3,
    color: TamaColors.text,
  );

  static const TextStyle titleM = TextStyle(
    fontFamily: TamaFonts.title,
    fontSize: 16,
    height: 1,
    letterSpacing: 0.3,
    color: TamaColors.text,
  );

  /// Numéro d'épisode traité comme un objet graphique.
  static const TextStyle numeral = TextStyle(
    fontFamily: TamaFonts.title,
    fontSize: 56,
    height: 0.8,
    color: TamaColors.text,
  );

  static const TextStyle body = TextStyle(
    fontFamily: TamaFonts.body,
    fontSize: 14,
    height: 1.45,
    color: TamaColors.text,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: TamaFonts.body,
    fontSize: 13,
    height: 1.45,
    color: TamaColors.textMuted,
  );

  /// Étiquette en capitales espacées (rubriques, unités).
  static const TextStyle label = TextStyle(
    fontFamily: TamaFonts.title,
    fontSize: 11,
    letterSpacing: 1.6,
    color: TamaColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontFamily: TamaFonts.title,
    fontSize: 15,
    letterSpacing: 0.9,
  );
}

/// Durées d'animation. Le mouvement ne coûte aucune donnée : uniquement
/// des transformations et de l'opacité.
abstract final class TamaMotion {
  /// Entrée d'un bloc.
  static const Duration enter = Duration(milliseconds: 420);

  /// Décalage entre deux blocs d'une même cascade.
  static const Duration stagger = Duration(milliseconds: 70);

  /// Respiration lente de la bannière.
  static const Duration breathe = Duration(seconds: 17);

  static const Curve easeOut = Curves.easeOutCubic;
}

/// Thème global construit à partir des jetons ci-dessus.
ThemeData buildTamaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: TamaFonts.body,
  );
  return base.copyWith(
    scaffoldBackgroundColor: TamaColors.background,
    colorScheme: const ColorScheme.dark(
      primary: TamaColors.accent,
      onPrimary: TamaColors.background,
      secondary: TamaColors.jaune,
      onSecondary: TamaColors.background,
      surface: TamaColors.surface,
      onSurface: TamaColors.text,
      error: TamaColors.error,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: TamaColors.text,
      displayColor: TamaColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: TamaColors.text,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TamaColors.accent,
        foregroundColor: TamaColors.background,
        textStyle: TamaText.button,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TamaRadius.chip),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TamaColors.text,
        side: const BorderSide(color: TamaColors.track, width: 1.5),
        textStyle: TamaText.button,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TamaRadius.chip),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: TamaColors.accent,
        textStyle: TamaText.button,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: TamaColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TamaRadius.sheet),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: TamaColors.surface,
      indicatorColor: TamaColors.accentSoft,
      height: 64,
      labelTextStyle: const WidgetStatePropertyAll(TamaText.label),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? TamaColors.accent
              : TamaColors.textMuted,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? TamaColors.accent
            : TamaColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? TamaColors.accentSoft
            : TamaColors.track,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: TamaColors.track,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: TamaColors.textMuted,
      textColor: TamaColors.text,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TamaColors.surfaceHigh,
      contentTextStyle: TamaText.body,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TamaRadius.chip),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TamaColors.background,
      hintStyle: TamaText.bodyMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TamaRadius.chip),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TamaRadius.chip),
        borderSide: const BorderSide(color: TamaColors.accent, width: 2),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TamaColors.accent,
      linearTrackColor: TamaColors.track,
      circularTrackColor: TamaColors.track,
    ),
  );
}
