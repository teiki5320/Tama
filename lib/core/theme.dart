import 'package:flutter/material.dart';

/// Jetons de design Tama.
/// Règle du projet : AUCUNE couleur, rayon ou taille de police en dur
/// ailleurs dans le code — tout est centralisé ici.
abstract final class TamaColors {
  /// Fond général de l'app.
  static const Color background = Color(0xFF0B0B0F);

  /// Surfaces : cartes, feuilles, barres.
  static const Color surface = Color(0xFF16161C);

  /// Texte principal.
  static const Color text = Color(0xFFF5F1E8);

  /// Accent doré — uniquement pour les actions et l'état actif, jamais en aplat.
  static const Color accent = Color(0xFFD4A343);

  /// Accent adouci (indicateurs, fonds d'état actif).
  static const Color accentSoft = Color(0x26D4A343);

  /// Texte atténué (métadonnées, légendes).
  static const Color textMuted = Color(0x99F5F1E8);

  /// Voile sombre derrière les overlays du player.
  static const Color scrim = Color(0x8A000000);

  /// Piste inactive (barres de progression, séparateurs).
  static const Color track = Color(0x26F5F1E8);

  /// Couleur d'erreur.
  static const Color error = Color(0xFFE5484D);

  /// Dégradés de repli pour les covers sans visuel (choisis par hachage du
  /// titre). Tons cinématographiques sombres, cohérents avec le fond.
  static const List<List<Color>> coverPalette = [
    [Color(0xFF3B2645), Color(0xFF14101E)],
    [Color(0xFF4A1E2B), Color(0xFF190D12)],
    [Color(0xFF1E3A4A), Color(0xFF0C161D)],
    [Color(0xFF44351C), Color(0xFF181307)],
    [Color(0xFF1E4436), Color(0xFF0B1A14)],
    [Color(0xFF3C2B4E), Color(0xFF120D1A)],
  ];
}

/// Rayons d'arrondi.
abstract final class TamaRadius {
  /// Vignettes et cartes.
  static const double card = 12;

  /// Feuilles modales.
  static const double sheet = 20;
}

/// Échelle d'espacement.
abstract final class TamaSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Familles de polices embarquées (voir pubspec.yaml).
abstract final class TamaFonts {
  /// Corps de texte.
  static const String body = 'Roboto';

  /// Titres : condensée, graisse forte.
  static const String title = 'RobotoCondensed';
}

/// Styles de texte. Titres : condensés, graisse forte. Corps : lisible dès 13 px.
abstract final class TamaText {
  static const TextStyle titleXL = TextStyle(
    fontFamily: TamaFonts.title,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    height: 1.05,
    color: TamaColors.text,
  );

  static const TextStyle titleL = TextStyle(
    fontFamily: TamaFonts.title,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.1,
    height: 1.1,
    color: TamaColors.text,
  );

  static const TextStyle titleM = TextStyle(
    fontFamily: TamaFonts.title,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: TamaColors.text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: TamaColors.text,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: TamaColors.textMuted,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: TamaColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
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
      secondary: TamaColors.accent,
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
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TamaRadius.card),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TamaColors.text,
        side: const BorderSide(color: TamaColors.track),
        textStyle: TamaText.button,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TamaRadius.card),
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
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? TamaColors.accent
            : TamaColors.textMuted,
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
      backgroundColor: TamaColors.surface,
      contentTextStyle: TamaText.body,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TamaRadius.card),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TamaColors.background,
      hintStyle: TamaText.bodyMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TamaRadius.card),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TamaRadius.card),
        borderSide: const BorderSide(color: TamaColors.accent),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TamaColors.accent,
      linearTrackColor: TamaColors.track,
      circularTrackColor: TamaColors.track,
    ),
  );
}
