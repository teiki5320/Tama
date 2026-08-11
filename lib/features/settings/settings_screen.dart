import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/favorites_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/repositories_providers.dart';
import '../../providers/settings_providers.dart';
import '../../services/connectivity_service.dart';
import 'auth_sheet.dart';

/// Réglages : compte, données réduites, qualité vidéo, langue, réseau.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);
    final isDemo = ref.watch(supabaseClientProvider) == null;
    final connectivity = ref.watch(connectivityProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          TamaSpacing.l,
          TamaSpacing.m,
          TamaSpacing.l,
          TamaSpacing.xxl,
        ),
        children: [
          const Text('Réglages', style: TamaText.titleXL),
          const SizedBox(height: TamaSpacing.xl),

          // ---- Compte -------------------------------------------------
          _Section(
            title: 'Compte',
            children: [
              if (isDemo)
                const ListTile(
                  leading: Icon(Icons.person_outline_rounded),
                  title: Text('Mode démo', style: TamaText.body),
                  subtitle: Text(
                    'Supabase non configuré — comptes désactivés pour l\'instant.',
                    style: TamaText.bodyMuted,
                  ),
                )
              else if (user == null)
                ListTile(
                  leading: const Icon(Icons.login_rounded),
                  title: const Text(
                    'Se connecter ou créer un compte',
                    style: TamaText.body,
                  ),
                  subtitle: const Text(
                    'Sauvegarde ta progression et tes favoris.',
                    style: TamaText.bodyMuted,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showAuthSheet(context),
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: Text(user.email ?? 'Mon compte',
                      style: TamaText.body),
                  subtitle:
                      const Text('Connecté', style: TamaText.bodyMuted),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title:
                      const Text('Se déconnecter', style: TamaText.body),
                  onTap: () async {
                    await ref
                        .read(supabaseClientProvider)
                        ?.auth
                        .signOut();
                    ref.read(progressVersionProvider.notifier).state++;
                    ref.invalidate(favoriteIdsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('À bientôt.')),
                      );
                    }
                  },
                ),
              ],
            ],
          ),

          // ---- Lecture ------------------------------------------------
          _Section(
            title: 'Lecture',
            children: [
              SwitchListTile(
                value: settings.dataSaver,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setDataSaver(v),
                title: const Text(
                  'Mode données réduites',
                  style: TamaText.body,
                ),
                subtitle: const Text(
                  '480p max et préchargement coupé — pensé pour la 3G.',
                  style: TamaText.bodyMuted,
                ),
              ),
              for (final quality in VideoQuality.values)
                _ChoiceTile(
                  label: 'Qualité ${quality.label}',
                  selected: settings.quality == quality,
                  enabled: !settings.dataSaver,
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setQuality(quality),
                ),
            ],
          ),

          // ---- Langue -------------------------------------------------
          _Section(
            title: 'Langue du contenu',
            children: [
              for (final language in ContentLanguage.values)
                _ChoiceTile(
                  label: language.label,
                  selected: settings.language == language,
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setLanguage(language),
                ),
            ],
          ),

          // ---- Réseau -------------------------------------------------
          _Section(
            title: 'Réseau',
            children: [
              ListTile(
                leading: const Icon(Icons.network_check_rounded),
                title: Text(
                  connectivity.when(
                    data: connectivityLabel,
                    loading: () => 'Détection…',
                    error: (_, __) => 'Inconnu',
                  ),
                  style: TamaText.body,
                ),
                subtitle:
                    const Text('Réseau actuel', style: TamaText.bodyMuted),
              ),
            ],
          ),

          const SizedBox(height: TamaSpacing.l),
          Center(
            child: Text(
              '${TamaConstants.appName} 0.1.0 — MVP',
              style: TamaText.label,
            ),
          ),
        ],
      ),
    );
  }
}

/// Groupe de réglages : titre en petites capitales + carte de surface.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: TamaSpacing.s),
          child: Text(title.toUpperCase(), style: TamaText.label),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: TamaColors.surface,
            borderRadius: BorderRadius.circular(TamaRadius.card),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: TamaSpacing.xl),
      ],
    );
  }
}

/// Ligne de choix exclusif (qualité, langue) — coche dorée sur l'état actif.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      title: Text(
        label,
        style: enabled ? TamaText.body : TamaText.bodyMuted,
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: TamaColors.accent)
          : null,
    );
  }
}
