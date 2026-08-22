# Prompt de dispatch — Claude Code

À coller au lancement d'une nouvelle session Claude Code sur
`teiki5320/Tama`. Le contexte projet (stack, conventions, état) est déjà
chargé automatiquement depuis `CLAUDE.md` — ce prompt ne porte que la
mission du jour. Remplacer la section `TÂCHE`.

---

Lis CLAUDE.md avant toute chose — il fait foi sur les conventions
(jetons de thème obligatoires, trois états par écran, mode démo à
préserver, analytics d'abord, commentaires en français).

## TÂCHE

<décrire ici la tâche du jour, par exemple :>
- corriger <bug observé, avec l'écran et le geste qui le déclenche>
- ajouter <fonctionnalité> sur l'écran <écran>
- brancher le backend réel (voir backlog de CLAUDE.md)

## Definition of done

1. `flutter analyze` à zéro et `flutter test` vert.
2. Le mode démo fonctionne toujours (lancement sans --dart-define).
3. Si l'UI change : captures d'écran des écrans touchés (390×844,
   build web) pour validation visuelle.
4. Commit avec message clair en français, poussé sur `main` — le studio
   ne crée pas de branche. Grouper les commits quand c'est possible :
   chaque poussée déclenche un build Xcode Cloud.
5. Ne pas créer de pull request sauf demande explicite.

## Garde-fous

- Le schéma SQL n'a jamais été appliqué sur le projet Supabase réel :
  tant que c'est le cas, la migration initiale s'édite sur place. Le jour
  où elle est exécutée, toute modification passe par un nouveau fichier
  de migration — et il faudra corriger cette ligne.
- Ne pas ajouter de dépendance sans la justifier en une ligne.
- En cas de doute sur un choix produit, choisir l'option la plus simple
  et le signaler dans le résumé final plutôt que de bloquer.
