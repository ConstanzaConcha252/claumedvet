## Context

- El logo real está embebido en `ClauMedVet.html` como JPEG en base64, en el `<img class="logo-img">` de la barra lateral. Es una imagen de 835×834, con fondo gris oscuro (~`#262626`) y el dibujo en turquesa ocupando aproximadamente el 55% central. Los metadatos dicen "logotipo veterinaria" (Illustrator).
- Los íconos actuales (`icon-192.png` e `icon-512.png`) son una huella dibujada con círculos blancos sobre `#1a8fa0`.
- `ClauMedVet.html` declara `<link rel="icon" href="./icon-192.png"/>` y `<link rel="apple-touch-icon" href="./icon-192.png"/>`.
- `manifest.json` declara los dos íconos con `purpose: "any maskable"`.
- El iPhone usa `apple-touch-icon` (ideal: 180×180) y guarda el ícono al momento de "Agregar a pantalla de inicio"; no lo actualiza después.

## Goals / Non-Goals

**Goals:**
- Que el ícono de la pantalla de inicio sea el logo real.
- Que el logo quede completo aunque el sistema recorte esquinas o lo muestre en círculo.

**Non-Goals:**
- Rediseñar el logo o cambiar sus colores.
- Cambiar el logo de la barra lateral o el de la pantalla de login.
- Generar íconos para todas las plataformas (Windows tiles, splash screens del iPhone, etc.).

## Decisions

### 1. Fuente: la imagen embebida de la barra lateral
Se extrae el JPEG del `<img class="logo-img">` y se generan los PNG con Python/Pillow, como paso de única vez fuera de la app. El script no queda en el repo. Así se usa exactamente el logo que ya aprobó Constanza, sin depender de un archivo externo.

### 2. Composición
**Elegido por Constanza tras ver vistas previas:** fondo turquesa de la app `#1a8fa0` y **todas las líneas en blanco**. Se descartaron el fondo gris original, los fondos turquesa claro y los tonos más oscuros (`#147a89`, `#145f6e`). Para recolorear, cada píxel del JPEG se descompone como mezcla del fondo `#282828` y los dos colores de trazo (`#3ea9af` y `#98fffc`); la suma de esos pesos se usa como opacidad del blanco sobre el fondo nuevo. Así se conservan los bordes suaves del logo.
- Lienzo cuadrado, relleno con `#1a8fa0`, **sin transparencia**: iOS pinta de negro las zonas transparentes.
- El logo se escala para que el dibujo quede dentro del 80% central (zona segura de los íconos "maskable") y conserve el margen que ya trae.
- Redimensionado con `LANCZOS` a 180, 192 y 512 px. Se guarda como PNG optimizado.

### 3. Nombre nuevo para el ícono del iPhone
`apple-touch-icon.png` (180×180) en vez de reutilizar `icon-192.png`. Es el nombre estándar que Safari también busca por defecto, y al ser una URL nueva evita copias guardadas del ícono viejo.

### 4. `manifest.json`
Las rutas no cambian. `background_color` pasa a `#1a8fa0`, el fondo del ícono, para que la pantalla de carga en Android combine con él. `theme_color` no se toca, porque es el color de la barra de la app.

### 5. Service worker
Se agrega `./apple-touch-icon.png` a `APP_SHELL` y `CACHE_NAME` pasa a `claumedvet-shell-v3`. El `activate` existente borra la v2.

## Risks / Trade-offs

- **El ícono no cambia en el iPhone ya instalado.** → Es una limitación de iOS: hay que borrar el ícono y volver a agregarlo desde Safari. Se le explica a Constanza; no se pierden datos.
- **Calidad:** la fuente es un JPEG de 835 px. Basta para 512 px, pero puede tener algo de compresión en los bordes. → Se revisa visualmente el resultado antes de publicar.
- **Fondo oscuro:** en la pantalla de inicio se verá un cuadrado oscuro con el dibujo turquesa, igual que en la barra lateral. Si Constanza prefiere otro fondo (por ejemplo, turquesa o blanco), se puede cambiar el color de relleno.

## Migration Plan

1. Generar los PNG, revisarlos visualmente y mostrárselos a Constanza.
2. Publicar.
3. En el iPhone: abrir la app con internet, borrar el ícono de la pantalla de inicio, abrir el sitio en Safari y volver a "Agregar a pantalla de inicio".

Rollback: revertir el commit (vuelven los PNG anteriores).

## Open Questions

- Ninguna bloqueante. El color de fondo se confirma con Constanza al ver la vista previa.
