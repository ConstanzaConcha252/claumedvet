## Why

Al iniciar sesión, sobre todo en el iPhone, es fácil equivocarse al escribir la contraseña sin poder ver lo que se escribió. Un botón para mostrarla evita intentos fallidos y tener que reescribirla.

Además, el logo de la pantalla de login (una casa simple con corazón, en SVG) no coincide con el ícono nuevo de la app (perro, gato y casa en blanco sobre turquesa). Constanza pidió que sean iguales.

## What Changes

- El logo de la pantalla de login pasa a ser la misma imagen del ícono de la app (`icon-512.png`). Se ve igual que la miniatura de la pantalla de inicio y funciona sin internet, porque el service worker ya guarda ese archivo.

- En la pantalla de login, el campo "Contraseña" tiene un botón con un ojo (👁) a la derecha, dentro del mismo campo.
- Al tocarlo, la contraseña se muestra; al tocarlo de nuevo, se oculta.
- La contraseña vuelve a quedar oculta después de cada intento de inicio de sesión, sea correcto o fallido.
- Se sube el `build`.

## Capabilities

### New Capabilities
- `login-password-visibility`: mostrar u ocultar la contraseña mientras se escribe en la pantalla de login.

### Modified Capabilities
- `app-icon`: se agrega el requisito de que el logo del login sea el mismo que el ícono de la app.

## Impact

- `ClauMedVet.html`:
  - HTML del campo `#loginPass`: un contenedor y un botón;
  - CSS mínimo para ubicar el botón dentro del campo;
  - función `togglePasswordVisibility()`;
  - `doLogin()` vuelve a ocultar la contraseña después de cada intento;
  - `<img class="login-logo">` cambia su `src` del SVG embebido a `./icon-512.png`.
- El logo de la barra lateral no cambia (sigue con los colores originales sobre fondo oscuro).
- Sin cambios en Supabase, RLS, service worker ni datos. La contraseña nunca se guarda ni se envía a ningún otro lado; solo cambia cómo se muestra en pantalla.
