{{flutter_js}}
{{flutter_build_config}}

// CanvasKit servi depuis le build lui-même : aucun CDN requis au chargement
// (fiabilité sur réseaux dégradés ou filtrés).
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
