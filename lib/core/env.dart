/// Variables d'environnement injectées à la compilation via `--dart-define`.
///
/// Exemple :
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String bunnyLibraryId =
      String.fromEnvironment('BUNNY_STREAM_LIBRARY_ID');
  static const String bunnyCdnHostname =
      String.fromEnvironment('BUNNY_STREAM_CDN_HOSTNAME');

  /// Vrai quand Supabase est configuré. Sinon, l'app tourne en mode démo
  /// avec des données locales : aucun backend requis pour la parcourir.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Vrai quand Bunny Stream est configuré (sinon vidéo de démonstration).
  static bool get hasBunny => bunnyCdnHostname.isNotEmpty;
}
