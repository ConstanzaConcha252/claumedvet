## Why

La app está instalada como PWA y el service worker guarda `ClauMedVet.html`, pero no guarda la librería `supabase-js`, que se carga desde jsdelivr. Sin internet, `supabase.createClient(...)` falla, el script principal se detiene y la app queda inutilizable (solo se ve la pantalla de login, sin funcionar). Esto pasa justo en el caso de uso real: visitas a domicilio en zonas rurales de Curicó con mala señal, donde Constanza necesita ver la ficha del paciente o la agenda.

Aunque se guarde la librería, hay un segundo bloqueo: si el token de sesión venció (dura ~1 hora), `getSession()` intenta renovarlo por internet, falla, y la app muestra el login, donde tampoco se puede entrar sin conexión.

## What Changes

- El service worker guarda una copia de la librería `supabase-js` y la usa cuando no hay internet.
- La URL de la librería se fija a una versión exacta (`@2.117.3`, la que se está usando hoy) en vez de `@2`, para que la copia guardada coincida siempre con la que pide la página.
- Si la librería no está disponible (por ejemplo, primera vez que se abre sin internet), la app muestra un mensaje claro en la pantalla de login en vez de romperse en silencio.
- Si no hay internet pero existe una sesión guardada en el dispositivo (Constanza no cerró sesión), la app abre en **modo consulta sin conexión** con los datos de la caché local, aunque el token haya vencido.
- En modo sin conexión se muestra un aviso visible: los cambios hechos sin internet no se guardan en la nube y se pueden perder al reconectar.
- Al volver internet, Supabase renueva el token solo y la app vuelve a sincronizar como hoy.
- Se sube la versión de la caché del service worker (`claumedvet-shell-v2`) para que los teléfonos ya instalados tomen el cambio.

Fuera de alcance (posible cambio futuro): guardar ediciones hechas sin conexión y subirlas al volver internet. Hoy `pullFromCloud()` reemplaza los datos locales con los de la nube, así que permitir editar offline de forma segura requiere una cola de cambios pendientes, lo que es un cambio mayor.

## Capabilities

### New Capabilities
- `offline-startup`: la app abre y permite consultar datos sin internet cuando ya se usó antes en ese dispositivo con sesión iniciada, y avisa claramente cuando está en modo sin conexión.

### Modified Capabilities
<!-- No hay specs existentes en openspec/specs/. -->

## Impact

- `service-worker.js`: guarda en caché la URL fija de `supabase-js` (solo esa URL externa; nunca respuestas de la API de Supabase) y sube la versión de caché.
- `ClauMedVet.html`:
  - etiqueta `<script>` de `supabase-js` con versión exacta;
  - protección alrededor de `supabase.createClient(...)`;
  - arranque (`getSession`) con respaldo a modo sin conexión;
  - aviso visual de modo sin conexión.
- Seguridad: no cambia RLS ni se agregan accesos para `anon`. El modo sin conexión solo muestra datos que ya están en el `localStorage` de ese mismo dispositivo y solo si hay una sesión guardada; al cerrar sesión deja de funcionar. Las llamadas a Supabase siguen usando `SB_HEADERS` / `setAuthHeader`.
- Sin nuevas dependencias ni archivos.
