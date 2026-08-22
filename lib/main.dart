import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'providers/repositories_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Affichage bord à bord (la barre système se pose sur le contenu).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await initSupabaseIfConfigured();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TamaApp(),
    ),
  );
}

class TamaApp extends ConsumerStatefulWidget {
  const TamaApp({super.key});

  @override
  ConsumerState<TamaApp> createState() => _TamaAppState();
}

class _TamaAppState extends ConsumerState<TamaApp> with WidgetsBindingObserver {
  /// Vrai quand l'app est passée en arrière-plan depuis la dernière
  /// ouverture. Sans ce drapeau, le `resumed` qui suit le lancement à froid
  /// doublerait l'`app_open` déjà émis par `start()`.
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Démarre le batching analytics et trace l'ouverture de l'app.
    ref.read(analyticsServiceProvider).start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // Mise en arrière-plan : on envoie immédiatement les événements en
      // file plutôt que de risquer de les perdre.
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _wasBackgrounded = true;
        ref.read(analyticsServiceProvider).flush();
      // Retour au premier plan. C'est CE moment qui mesure la rétention :
      // sur iOS une app reste des jours en arrière-plan sans que son
      // processus soit tué, et un testeur qui rouvre Tama chaque matin
      // n'émettrait sinon qu'un seul `app_open`, le jour de l'installation.
      case AppLifecycleState.resumed:
        if (_wasBackgrounded) {
          _wasBackgrounded = false;
          ref.read(analyticsServiceProvider).track('app_open');
        }
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: TamaConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTamaTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
