## 1. Librería de login con versión fija

- [x] 1.1 En `ClauMedVet.html`, cambiar la etiqueta `<script>` de `supabase-js@2` a `supabase-js@2.117.3` y agregar `crossorigin="anonymous"`

## 2. Service worker

- [x] 2.1 Cambiar `CACHE_NAME` a `claumedvet-shell-v2`
- [x] 2.2 Agregar la constante `SUPABASE_JS_URL` con la misma URL exacta del paso 1.1
- [x] 2.3 En `install`, precargar `SUPABASE_JS_URL` con `mode: 'cors'`, por separado del `addAll` del app shell
- [x] 2.4 En `fetch`, responder `SUPABASE_JS_URL` con "caché primero" y, si no está, descargarla y guardarla solo si `response.ok`; mantener el `return` para cualquier otra URL de otro origen (nunca interceptar `*.supabase.co`)
- [x] 2.5 En la rama del mismo origen, guardar en caché solo respuestas con `response.ok`

## 3. Protección si la librería no carga

- [x] 3.1 Crear `sbAuth` solo si `typeof supabase !== 'undefined'`; si no, dejarlo en `null`
- [x] 3.2 Si `sbAuth` es `null`, mostrar en `#loginError` "Se necesita conexión a internet para abrir ClauMedVet por primera vez" y deshabilitar el botón Entrar
- [x] 3.3 Proteger con `if (sbAuth)` los usos en `doLogin`, `doLogout`, `onAuthStateChange` y `getSession`

## 4. Modo consulta sin conexión

- [x] 4.1 Agregar `hasStoredSession()`: arma la clave `sb-<ref>-auth-token` desde `SUPABASE_URL` y confirma que exista con `refresh_token`
- [x] 4.2 Agregar `isNetworkError(error)`: `AuthRetryableFetchError` o `status === 0`
- [x] 4.3 Agregar `startAppOffline()`: oculta el login, carga datos locales y renderiza, deja `cloudStatus='offline'` y `offlineMode=true` y muestra el aviso; sin `pullFromCloud`, `initSampleData` ni `syncAllToCloud`
- [x] 4.4 Cambiar el `.then` de `getSession()` para que use `startAppOffline()` cuando no hay sesión, hay sesión guardada y la red falla
- [x] 4.5 En `onAuthStateChange`: si `offlineMode` y llega una sesión, actualizar el header, salir del modo offline, ocultar el aviso y ejecutar `pullFromCloud().then(renderAll)`; si llega `SIGNED_OUT` en modo offline, hacer `location.reload()`

## 5. Aviso visual

- [x] 5.1 Agregar `#offlineBanner` (oculto por defecto) con el texto del aviso y un CSS mínimo con los colores existentes
- [x] 5.2 Confirmar que el aviso no tape la barra lateral ni los botones en el iPhone (ancho móvil)

## 6. Pruebas

- [x] 6.1 Revisar que no haya errores de sintaxis: abrir la app con `python -m http.server` y mirar la consola
- [ ] 6.2 (Caché verificada: tiene `supabase.js` y nada de `supabase.co`. Falta que Constanza pruebe el login real en 6.8.) Escritorio, con internet: login, sincronización y ☁️ funcionan igual que antes; en DevTools → Application aparece la caché `claumedvet-shell-v2` con `supabase.js`, sin respuestas de `supabase.co`
- [x] 6.3 Escritorio, DevTools → Network "Offline": la app abre con los datos locales, muestra 📴 y el aviso
- [x] 6.4 Simular un token vencido (editar `expires_at` en la sesión guardada) y abrir offline: la app abre en modo consulta y la sesión guardada **no** se borra. Si se borra, mover `hasStoredSession()` antes de `getSession()` según el design
- [ ] 6.5 (Requiere la sesión real de Constanza, se prueba en 6.8) Volver a "Online": el aviso desaparece, el token se renueva y se sincroniza
- [x] 6.6 Cerrar sesión y abrir offline: se muestra el login y no se ven datos
- [x] 6.7 Borrar la caché del service worker y abrir offline: se ve el mensaje "Se necesita conexión…" y no hay errores en la consola
- [ ] 6.8 Publicar y, en el iPhone, abrir la PWA una vez con internet; después probar en modo avión (Constanza)
