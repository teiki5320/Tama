/// Reconnaissance des identifiants acceptables par Postgres.
///
/// Les colonnes `id` de Supabase sont des `uuid`. Or la progression de
/// lecture vit d'abord en local, et elle survit au passage du mode démo au
/// vrai backend : un appareil qui a regardé le catalogue de démonstration
/// garde des identifiants comme « demo-serie-1-ep3 ». Envoyés tels quels
/// dans un `in.(…)`, ils font échouer la requête entière avec
/// `invalid input syntax for type uuid` — et c'est tout le rail
/// « Reprendre » qui tombe, pas seulement la ligne fautive.
library;

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Vrai si [value] peut être passé à une colonne `uuid` sans faire échouer
/// la requête. Les dépôts Supabase s'en servent pour ignorer en silence ce
/// que la base ne saurait de toute façon pas retrouver.
bool isUuid(String value) => _uuid.hasMatch(value);
