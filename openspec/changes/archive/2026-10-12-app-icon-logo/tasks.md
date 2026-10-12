## 1. Generar íconos

- [x] 1.1 Extraer el JPEG del `<img class="logo-img">` de la barra lateral (fuera del repo, en el scratchpad)
- [x] 1.2 Generar `apple-touch-icon.png` (180×180), `icon-192.png` e `icon-512.png`: fondo `#1a8fa0` con todas las líneas en blanco (elegido por Constanza), sin transparencia, con el dibujo dentro del 80% central
- [x] 1.3 Revisar visualmente los tres PNG, incluido cómo se ven con esquinas redondeadas y en círculo, y mostrarle la vista previa a Constanza

## 2. Conectar los íconos

- [x] 2.1 En `ClauMedVet.html`, cambiar `<link rel="apple-touch-icon">` a `./apple-touch-icon.png`
- [x] 2.2 En `manifest.json`, cambiar `background_color` a `#1a8fa0`
- [x] 2.3 En `service-worker.js`, agregar `./apple-touch-icon.png` a `APP_SHELL` y cambiar `CACHE_NAME` a `claumedvet-shell-v3`
- [x] 2.4 Subir el `build` en `ClauMedVet.html` (2 lugares)

## 3. Pruebas

- [x] 3.1 `node --check` del service worker y del JS del HTML
- [x] 3.2 Servidor local: los tres íconos responden 200, el manifest es JSON válido y la caché `claumedvet-shell-v3` incluye `apple-touch-icon.png`
- [x] 3.3 Repetir las pruebas sin conexión ya existentes para confirmar que no se rompió nada
- [x] 3.4 (Confirmado por Constanza en el iPhone con build 2026-10-12.1.) Publicar y, en el iPhone, borrar el ícono, volver a agregarlo desde Safari y confirmar que aparece el logo (Constanza)
