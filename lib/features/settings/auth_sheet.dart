import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../providers/favorites_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/repositories_providers.dart';

/// Ouvre la feuille de connexion/inscription.
Future<void> showAuthSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const AuthSheet(),
  );
}

/// Connexion / inscription par email. N'apparaît qu'au moment où un compte
/// devient nécessaire (favori, sauvegarde de progression multi-appareils).
class AuthSheet extends ConsumerStatefulWidget {
  const AuthSheet({super.key});

  @override
  ConsumerState<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<AuthSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signUpMode = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      setState(() {
        _error = 'Mode démo : configure Supabase pour activer les comptes.';
      });
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Renseigne ton email et ton mot de passe.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_signUpMode) {
        await client.auth.signUp(email: email, password: password);
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Compte créé — vérifie ta boîte mail pour confirmer.'),
          ),
        );
      } else {
        await client.auth.signInWithPassword(email: email, password: password);
        // La progression anonyme locale suit l'utilisateur sur son compte.
        await ref.read(progressRepositoryProvider).syncLocalToRemote();
        ref.read(progressVersionProvider.notifier).state++;
        ref.invalidate(favoriteIdsProvider);
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bon retour sur Tama.')),
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Connexion impossible. Réessaie.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TamaSpacing.l,
        TamaSpacing.m,
        TamaSpacing.l,
        MediaQuery.of(context).viewInsets.bottom + TamaSpacing.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TamaColors.track,
                borderRadius: BorderRadius.circular(TamaRadius.card),
              ),
            ),
          ),
          const SizedBox(height: TamaSpacing.l),
          Text(
            _signUpMode ? 'Créer un compte' : 'Se connecter',
            style: TamaText.titleL,
          ),
          const SizedBox(height: TamaSpacing.xs),
          const Text(
            'Sauvegarde ta progression et tes favoris.',
            style: TamaText.bodyMuted,
          ),
          const SizedBox(height: TamaSpacing.l),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'Email'),
          ),
          const SizedBox(height: TamaSpacing.m),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Mot de passe (6 caractères min.)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: TamaSpacing.m),
            Text(
              _error!,
              style: TamaText.bodyMuted.copyWith(color: TamaColors.error),
            ),
          ],
          const SizedBox(height: TamaSpacing.l),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_signUpMode ? 'Créer mon compte' : 'Se connecter'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _signUpMode = !_signUpMode;
                        _error = null;
                      }),
              child: Text(
                _signUpMode
                    ? 'J\'ai déjà un compte — me connecter'
                    : 'Pas encore de compte ? En créer un',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
