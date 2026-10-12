## Why

Al agregar ClauMedVet a la pantalla de inicio del iPhone, el ícono es una huella simplificada (círculos blancos sobre turquesa) que no se reconoce como el logo de la clínica. El logo real ya existe dentro de la app: es la imagen de la barra lateral (perro y gato junto a una casa con corazón, sobre fondo oscuro), pero no se usa para el ícono.

## What Changes

- Se generan los íconos de la app a partir del logo real que ya está en la barra lateral:
  - `icon-192.png` y `icon-512.png`, que usa el `manifest.json` (Android y otros);
  - un archivo nuevo, `apple-touch-icon.png` de 180×180, que es el tamaño que usa el iPhone para la pantalla de inicio.
- `ClauMedVet.html` apunta `apple-touch-icon` al archivo nuevo de 180×180. Se usa un nombre nuevo para que el iPhone no use una copia guardada del ícono anterior.
- El service worker guarda también el ícono nuevo y la caché sube de versión.
- Se sube el `build`.
- Para ver el ícono nuevo hay que **borrar el ícono actual de la pantalla de inicio y volver a agregarlo** desde Safari. El iPhone guarda el ícono al momento de agregarlo y no lo actualiza solo. No se pierden datos.

## Capabilities

### New Capabilities
- `app-icon`: la app instalada muestra el logo de ClauMedVet como ícono en la pantalla de inicio.

### Modified Capabilities
<!-- Ninguna: no cambian requisitos de offline-startup ni offline-sync. -->

## Impact

- Archivos de imagen: `icon-192.png` y `icon-512.png` se reemplazan; se agrega `apple-touch-icon.png`.
- `ClauMedVet.html`: una línea (`<link rel="apple-touch-icon">`) y el número `build`.
- `service-worker.js`: agrega el ícono nuevo al app shell y cambia la caché a `claumedvet-shell-v3`.
- `manifest.json`: sin cambios de rutas. Se revisa que `background_color` combine con el fondo oscuro del logo.
- Sin cambios de seguridad, RLS ni datos.
