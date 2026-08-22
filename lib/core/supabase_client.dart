import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// État de la connexion au backend, décidé une fois pour toutes au démarrage.
enum SupabaseStatus {
  /// Aucune clé fournie : l'app tourne sur les données locales. C'est le
  /// mode de développement, voulu et documenté.
  demo,

  /// Backend joignable.
  ready,

  /// Des clés ont été fournies mais l'initialisation a échoué — clé mal
  /// recopiée, projet supprimé, URL invalide.
  failed,
}

SupabaseStatus _status = SupabaseStatus.demo;

/// État courant du backend. Lu par `supabaseClientProvider` et affiché dans
/// les réglages : un testeur doit pouvoir dire *pourquoi* rien ne remonte.
SupabaseStatus get supabaseStatus => _status;

/// Initialise Supabase si les variables d'environnement sont fournies.
///
/// L'échec ne remonte jamais jusqu'à `main()` : une clé mal recopiée dans
/// les variables Xcode Cloud rendrait sinon l'app impossible à lancer —
/// écran noir, aucun message, et un nouveau build pour s'en sortir. On
/// retombe sur le mode démo, et les réglages le disent.
Future<void> initSupabaseIfConfigured() async {
  if (!Env.hasSupabase) {
    _status = SupabaseStatus.demo;
    return;
  }
  try {
    // `publishableKey` accepte aussi bien la nouvelle clé publiable que la
    // clé anon historique de Supabase.
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
    _status = SupabaseStatus.ready;
  } catch (e) {
    _status = SupabaseStatus.failed;
    debugPrint('[Tama] Initialisation Supabase impossible : $e');
  }
}
