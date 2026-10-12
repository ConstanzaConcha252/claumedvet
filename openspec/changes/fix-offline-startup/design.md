## Context

`ClauMedVet.html` carga `supabase-js` desde `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js` (línea ~414) y en la línea ~680 ejecuta `const sbAuth = supabase.createClient(...)` a nivel global. El service worker (`service-worker.js`, caché `claumedvet-shell-v1`) solo intercepta peticiones del mismo origen (`url.origin !== self.location.origin → return`), así que la librería nunca se guarda en la caché. Sin internet, `supabase` no existe, esa línea lanza un `ReferenceError` y se detiene todo el script principal.

El arranque actual es:

```js
sbAuth.auth.getSession().then(({ data }) => {
  if (data.session) { setAuthHeader(...); startAppAfterLogin(); }
});
```

`startAppAfterLogin()` carga `localStorage` y luego llama a `pullFromCloud()`. Si `pullFromCloud()` falla y no hay pacientes locales, ejecuta `initSampleData(); syncAllToCloud();`.

`supabase-js` guarda la sesión en `localStorage` con la clave `sb-jxhotwoeaozlqtujwodz-auth-token`. El access token dura ~1 hora; al vencer, `getSession()` intenta renovarlo por red. Sin red, devuelve `session: null` con un error de red (`AuthRetryableFetchError`), pero no borra la sesión guardada.

## Goals / Non-Goals

**Goals:**
- Que la PWA abra sin internet si ya se usó antes con sesión iniciada en ese dispositivo.
- Que se puedan consultar pacientes, agenda y cobros guardados localmente.
- Avisar claramente cuando la app está sin conexión y que los cambios pueden perderse.
- Que, sin la librería, la app muestre un mensaje en vez de romperse en silencio.

**Non-Goals:**
- Guardar ediciones hechas offline y subirlas después (cola de sincronización). Es un cambio aparte.
- Hacer que la app funcione offline la primera vez en un dispositivo nuevo.
- Guardar en caché Google Fonts o la librería `xlsx` (exportar a Excel). Sin internet se usan fuentes del sistema y el Excel no se puede exportar; las dos cosas son aceptables.
- Cambiar RLS, Storage o la forma de autenticarse.

## Decisions

### 1. Fijar la versión de `supabase-js` y cargarla con `crossorigin`
Se cambia la etiqueta a:
```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.117.3/dist/umd/supabase.js" crossorigin="anonymous"></script>
```
- `2.117.3` es la versión a la que resuelve `@2` hoy, así que no cambia el comportamiento.
- Con la URL fija, la copia guardada siempre corresponde a lo que pide la página. Con `@2`, la caché podría quedar con una versión vieja sin que nadie lo note.
- `crossorigin="anonymous"` hace que la petición sea CORS. jsdelivr responde con `Access-Control-Allow-Origin: *`, así que la respuesta no es "opaca": se puede validar (`response.ok`) y no infla el uso de almacenamiento.
- Alternativa descartada: copiar `supabase.js` dentro del repo. Funciona, pero agrega un archivo de ~150 KB que habría que actualizar a mano, y el proyecto hoy no tiene dependencias locales.

### 2. Service worker: lista permitida explícita y "caché primero" para la librería
- Constante `SUPABASE_JS_URL` con la URL exacta.
- En `install` se precarga con `cache.add(new Request(SUPABASE_JS_URL, { mode: 'cors' }))`, por separado del `addAll` del app shell, para que un fallo no impida guardar lo demás.
- En `fetch`: si `event.request.url === SUPABASE_JS_URL`, se responde desde la caché; si no está, se descarga, se guarda (solo si `response.ok`) y se entrega. Una URL con versión fija no cambia, así que "caché primero" es seguro.
- Toda otra petición de otro origen sigue con `return` (no se intercepta). En especial, nada de `*.supabase.co`: los datos clínicos nunca entran a la caché del service worker.
- `CACHE_NAME` pasa a `claumedvet-shell-v2`. El `activate` existente borra la v1.
- Arreglo menor en la misma función: solo guardar respuestas del mismo origen si `response.ok`, para no dejar un 404 guardado como "última copia".

### 3. Protección si `supabase` no existe
```js
const sbAuth = (typeof supabase !== 'undefined') ? supabase.createClient(SUPABASE_URL, SUPABASE_KEY) : null;
```
Los cuatro usos de `sbAuth` se protegen: `doLogin`, `doLogout`, `onAuthStateChange` y `getSession`. Si es `null`, se muestra en `#loginError` el mensaje "Se necesita conexión a internet para abrir ClauMedVet por primera vez" y el botón Entrar queda deshabilitado.

### 4. Arranque con respaldo a modo sin conexión
```js
sbAuth.auth.getSession().then(({ data, error }) => {
  if (data.session) { setAuthHeader(data.session.access_token); startAppAfterLogin(); return; }
  if (hasStoredSession() && (!navigator.onLine || isNetworkError(error))) startAppOffline();
});
```
- `hasStoredSession()`: lee `localStorage['sb-jxhotwoeaozlqtujwodz-auth-token']` y confirma que tenga `refresh_token`. La clave se arma a partir de `SUPABASE_URL` para no repetir el ID del proyecto.
- `isNetworkError(error)`: `error?.name === 'AuthRetryableFetchError'` o `error?.status === 0`. Se usa además de `navigator.onLine` porque en iPhone `onLine` puede ser `true` con señal mala.
- `startAppOffline()`: oculta el login y ejecuta `loadDB(); loadTarifasLocal(); restoreViewState(); renderAll();`, con `cloudStatus = 'offline'` y `offlineMode = true`. Muestra el aviso. **No** llama a `pullFromCloud()` ni a `initSampleData()/syncAllToCloud()`, para que nunca se suban datos de ejemplo.
- `SB_HEADERS` queda con la publishable key (`setAuthHeader(null)`). Cualquier `push*` sin red falla como hoy y marca 📴.

**Ajuste hecho durante la implementación:** las pruebas mostraron que, sin red, `getSession()` puede tardar hasta ~30 s, porque `supabase-js` reintenta renovar el token. Por eso, si hay sesión guardada, un temporizador abre el modo sin conexión a los **1,5 s** (si `navigator.onLine` es `false`) o a los **4 s** (si hay "señal mala"). El temporizador se cancela si `getSession()` responde antes. Si la sesión llega después, se sale solo del modo sin conexión. Si Supabase rechaza y borra la sesión guardada, se recarga y se muestra el login.

### 5. Volver a estar en línea
`supabase-js` tiene `autoRefreshToken` activo: al recuperar la red, renueva el token y dispara `onAuthStateChange` con la sesión. En ese listener:
- si `offlineMode` y llega una sesión: `setAuthHeader(...)`, `offlineMode = false`, se oculta el aviso y se ejecuta `pullFromCloud().then(renderAll)`, igual que en un arranque normal;
- si llega `SIGNED_OUT` (por ejemplo, el refresh token fue revocado): `location.reload()` para volver al login.

Además, al volver la señal (evento `online`) o al volver a la app (`visibilitychange`), se llama a `getSession()` para intentar salir del modo sin conexión.

### 6. Aviso visual
**Implementado abajo, no arriba:** en el iPhone, una franja arriba tapaba la barra superior. Quedó como franja fija **abajo**, que respeta la zona segura del iPhone y se oculta con un toque. El 📴 del indicador sigue visible.

Diseño original: una franja fija y discreta arriba (`#offlineBanner`, oculta por defecto) con el texto: "📴 Sin conexión: estás viendo datos guardados en este teléfono. Los cambios que hagas ahora pueden perderse al volver internet." Se usan los colores existentes y un CSS mínimo, sin reorganizar el layout.

## Risks / Trade-offs

- **Ediciones offline se pierden.** Al reconectar, `pullFromCloud()` reemplaza los datos locales. → Mitigación: el aviso visible y el documento lo dejan como fuera de alcance. Si molesta en la práctica, se hace un cambio aparte con una cola de cambios pendientes.
- **Comportamiento de `getSession()` sin red en 2.117.3.** El diseño asume que no borra la sesión guardada ante errores de red. → Mitigación: se prueba explícitamente en las tareas. Si sí la borra, `hasStoredSession()` se evalúa **antes** de llamar a `getSession()`.
- **Señal intermitente:** `getSession()` puede tardar hasta que el fetch falle. → Aceptable: la app abre igual cuando falla. No se agrega timeout para mantener el cambio chico.
- **Exposición de datos:** el modo offline solo muestra lo que ya está en `localStorage` de ese dispositivo y solo si no se cerró sesión. Es lo mismo que hoy, donde la app abre directo con la sesión guardada. Al cerrar sesión, deja de abrir offline.
- **Primera carga tras el despliegue:** el teléfono necesita abrir la app una vez con internet para instalar el nuevo service worker. → Se incluye en las tareas de prueba.

## Migration Plan

1. Desplegar con push a `main` (GitHub Pages).
2. En el iPhone, abrir la app instalada con internet una vez y cerrarla.
3. Probar en modo avión.

Rollback: revertir el commit. El `activate` del service worker borra cachés con otro nombre, así que volver a `v1` limpia la `v2`.

## Open Questions

- Ninguna bloqueante.
