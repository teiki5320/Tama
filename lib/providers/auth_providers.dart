import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repositories_providers.dart';

/// Flux des changements d'état d'authentification Supabase.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const Stream.empty();
  return client.auth.onAuthStateChange;
});

/// Utilisateur courant (null si anonyme ou en mode démo).
final currentUserProvider = Provider<User?>((ref) {
  // On observe le flux pour se reconstruire à chaque connexion/déconnexion.
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider)?.auth.currentUser;
});

final isLoggedInProvider =
    Provider<bool>((ref) => ref.watch(currentUserProvider) != null);
