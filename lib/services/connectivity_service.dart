import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État réseau courant, exposé aux réglages (et à de futurs ajustements
/// automatiques de qualité en phase 2).
final connectivityProvider = StreamProvider<List<ConnectivityResult>>(
  (ref) => Connectivity().onConnectivityChanged,
);

/// Libellé lisible du réseau courant.
String connectivityLabel(List<ConnectivityResult> results) {
  if (results.contains(ConnectivityResult.wifi)) return 'Wi-Fi';
  if (results.contains(ConnectivityResult.mobile)) return 'Données mobiles';
  if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
  if (results.contains(ConnectivityResult.none)) return 'Hors ligne';
  return 'Inconnu';
}
