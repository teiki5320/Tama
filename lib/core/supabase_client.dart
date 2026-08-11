import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Initialise Supabase si les variables d'environnement sont fournies.
/// Sans configuration, l'app fonctionne en mode démo (données locales).
Future<void> initSupabaseIfConfigured() async {
  if (!Env.hasSupabase) return;
  // `publishableKey` accepte aussi bien la nouvelle clé publiable que la
  // clé anon historique de Supabase.
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );
}
