## Context

El login (`#loginScreen`) tiene `<input type="password" id="loginPass" autocomplete="current-password">` dentro de un `.login-field`. `doLogin()` lee el valor y, si falla, vacía el campo y le devuelve el foco. Los listeners del login se conectan en `DOMContentLoaded`. Es el único campo de contraseña de la app.

## Goals / Non-Goals

**Goals:** mostrar u ocultar la contraseña con un botón dentro del campo, cómodo en el iPhone.

**Non-Goals:** recuperar contraseña, recordar contraseña, cambiar el flujo de login o Supabase Auth.

## Decisions

1. **Alternar `type` entre `password` y `text`.** Es lo estándar. Se mantiene `autocomplete="current-password"`, así que el llavero de iCloud sigue funcionando.
2. **Botón dentro del campo:** se envuelve el input en `<div class="pw-wrap">` con `position:relative`, y se agrega un `<button type="button" class="pw-toggle">` posicionado a la derecha. El input gana `padding-right` para que el texto no quede debajo del botón. `type="button"` evita que el botón dispare el login.
3. **Ícono:** emoji 👁 (oculta) y 🙈 (visible), igual que los otros emojis de la app (🔒, 📴). Sin librerías ni SVG nuevos.
4. **Foco:** en `mousedown`/`pointerdown` se hace `preventDefault()` para que el input no pierda el foco y en el iPhone no se cierre y vuelva a abrir el teclado.
5. **Accesibilidad:** `aria-label` y `aria-pressed` se actualizan en cada cambio. Área táctil de 40×40 px.
6. **Volver a ocultar:** `doLogin()` llama a `setPasswordVisible(false)` al empezar cada intento.
7. **Logo del login:** `<img class="login-logo">` pasa de un SVG embebido a `src="./icon-512.png"`. Se usa el de 512 px para que se vea nítido en pantallas retina (se muestra a 72 px). Ya está en `APP_SHELL`, así que funciona sin conexión. El CSS `.login-logo` (72×72, `border-radius:12px`) se mantiene: queda como un ícono de app con esquinas redondeadas.

## Risks / Trade-offs

- **Alguien mirando la pantalla:** mostrarla es decisión de la usuaria, y la contraseña vuelve a ocultarse en cada intento. → Riesgo aceptable.
- **Fuente en el iPhone:** el input ya tiene `font-size:16px` en móvil (evita el zoom automático). Se mantiene.

## Migration Plan

Publicar. Es un cambio solo visual del login; para revertirlo, se revierte el commit.

## Open Questions

Ninguna.
