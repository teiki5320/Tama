# Bunny Stream — la bibliothèque de Tama

Créée le 22/08/2026. Ces valeurs ne sont pas des secrets : elles figurent
dans les URLs que l'app appelle. **La clé API, elle, ne doit jamais entrer
dans le dépôt.**

| | |
|---|---|
| Bibliothèque | `Tama` |
| Video Library ID | `734067` |
| CDN hostname | `vz-c110e438-e92.b-cdn.net` |
| Régions | Francfort (principale) + Los Angeles, New York, Singapour |

Johannesburg a été volontairement écartée : c'est la seule région Afrique
de Bunny, mais le trafic d'Afrique de l'Ouest remonte vers l'Europe par
les câbles sous-marins — Francfort sert mieux Dakar ou Abidjan que
l'Afrique du Sud. Une région s'ajoute plus tard, elle ne se retire jamais.

## Réglage de sécurité indispensable

**« Block direct url file access » doit rester désactivé** (Stream →
bibliothèque → Security → General). Activé — c'est le défaut — il bloque
toute requête dépourvue d'en-tête `referer`, ce qu'une app mobile n'envoie
jamais : vignettes, playlists HLS et MP4 renvoient tous 403.

Ce n'est pas une perte de protection sérieuse : un `referer` se falsifie
en une ligne. La vraie protection serait l'authentification par jeton, qui
exige de signer chaque URL avec une clé secrète — donc un serveur, que le
projet a écarté. À reprendre le jour où le catalogue aura de la valeur.

Les deux jetons (`Embed view token` et `CDN token`) sont désactivés.

## Adresses servies par le CDN

```
https://{cdn}/{videoId}/playlist.m3u8      lecture adaptative (qualité Auto)
https://{cdn}/{videoId}/play_480p.mp4      mode données réduites
https://{cdn}/{videoId}/play_720p.mp4      qualité forcée
https://{cdn}/{videoId}/thumbnail.jpg      vignette — sert d'affiche de série
```

Vérifié le 22/08/2026 : les quatre répondent 200, et les vignettes sortent
en **1080 × 1920**, donc directement utilisables comme affiches.

## Épisodes en ligne

| N° | Titre | Video ID |
|---|---|---|
| 1 | Chambre 307 | `9d3d233a-13a0-4ef0-9967-5455e4e061d8` |
| 2 | Achète mes poulets | `799d7c29-fabf-44f3-bf2e-cc9fc7a17d41` |
| 3 | Le collier dans la poubelle | `7fb57eda-368e-4063-b3fe-e9c21e3f7796` |

Durées : 1 min 13 à 1 min 17. Fichiers sources de 240 à 270 Mo.

## Deux constats sur ces vidéos

- **Les sous-titres sont incrustés dans l'image**, en bas — là où l'app
  pose le titre de la série sur une affiche. Les deux se superposent. À
  trancher : titre en haut sur les affiches issues d'une vignette, ou
  vignette choisie sur un instant sans dialogue.
- **Un filigrane `toa.afrotok`** figure en haut à droite. Rien ne peut le
  retirer côté app : c'est à régler à la source.

## Ce qui manque pour brancher le catalogue

1. Le titre de la série, son genre et son synopsis.
2. La migration exécutée sur le projet Supabase réel.
3. Les clés Supabase posées dans les variables du processus Xcode Cloud,
   et transmises par `ci_post_clone.sh` à `flutter build`.
