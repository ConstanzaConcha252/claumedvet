## 0. Prerrequisito

- [ ] 0.1 Confirmar que `fix-offline-startup` está implementado y probado (existen `offlineMode`, `startAppOffline()` y `#offlineBanner`)

## 1. Estado de pendientes

- [ ] 1.1 Agregar `loadPending()` y `savePending()` para `claudmedvet_pending_v1` (`dirty`, `rev`, `deletes`, `created`), con `try/catch` igual que el resto de los accesos a `localStorage`
- [ ] 1.2 En `saveDB()`, marcar `dirty = true` y `rev++` antes de sincronizar
- [ ] 1.3 Registrar el nuevo ID en `pending.created` en los 4 lugares donde se crean registros (paciente ~2003, cita ~2420, cobro ~2522 y ~2674)

## 2. Sincronización que se puede esperar

- [ ] 2.1 Crear `syncNow()` con ejecución única (`inFlight` + `rerun`) y salida temprana si no hay sesión válida
- [ ] 2.2 Paso de borrados: enviar la cola `deletes` y sacar los que salen bien
- [ ] 2.3 Paso de choques: `GET ?select=id&id=in.(…)` por tabla para `created`; si hay coincidencias, detener, estado `error`, detalle y `alert` una vez por sesión
- [ ] 2.4 Paso de upserts: `Promise.all` por tabla y, al terminar bien cada tabla, sacar de `created` los IDs del snapshot de esa tabla
- [ ] 2.5 Paso de config: leer `next_*_id` de la nube y subir `max(local, nube)` junto con `tarifas`
- [ ] 2.6 Al terminar: limpiar `dirty` solo si `rev` no cambió; actualizar `cloudStatus` y `renderCloudBadge()`
- [ ] 2.7 Hacer que `syncAllToCloud()` llame a `syncNow()` sin esperar, para que los llamados existentes sigan funcionando

## 3. Borrados sin conexión

- [ ] 3.1 En `pushDeletePatient/Appt/Invoice`, si falla por red, agregar a `pending.deletes`, marcar `dirty` y sacar el ID de `created` si estaba

## 4. Orden subir → descargar

- [ ] 4.1 `startAppAfterLogin()`: si `pending.dirty`, hacer `await syncNow()` y solo si sale bien llamar a `pullFromCloud()`; si falla, no llamar a `initSampleData()`
- [ ] 4.2 `onAuthStateChange`: ante `SIGNED_IN` o `TOKEN_REFRESHED` con `dirty`, ejecutar `syncNow()` y luego `pullFromCloud().then(renderAll)`
- [ ] 4.3 Agregar el listener `window 'online'` que ejecuta `syncNow()` si hay sesión y `dirty`

## 5. Interfaz

- [ ] 5.1 Cambiar el texto de `#offlineBanner` a "📴 Sin conexión: tus cambios se guardan en este teléfono y se subirán cuando vuelva internet."
- [ ] 5.2 En `renderCloudBadge()`, agregar " · cambios por subir" cuando `pending.dirty`

## 6. Pruebas (escritorio con `python -m http.server` y DevTools)

- [ ] 6.1 Consola sin errores al cargar; con internet, crear, editar y borrar funcionan como antes y no queda `dirty`
- [ ] 6.2 Offline: registrar consulta, vacuna, cita, cobro y paciente nuevo; el indicador muestra "cambios por subir"
- [ ] 6.3 Recargar offline: los cambios siguen y siguen pendientes
- [ ] 6.4 Volver "Online" con la app abierta: se suben solos y, al revisar en el dashboard de Supabase, están todos
- [ ] 6.5 Repetir offline, cerrar la pestaña, volver online y abrir: se suben antes de descargar y nada se pierde
- [ ] 6.6 Borrar una cita offline y reconectar: no reaparece y en Supabase ya no existe
- [ ] 6.7 Choque: crear una cita offline en una pestaña y otra con el mismo ID desde otra ventana con internet; al reconectar aparece el aviso, no se sube nada y los datos locales siguen
- [ ] 6.8 Adjuntar receta y examen offline: aparece el aviso existente y el formulario no se cierra
- [ ] 6.9 Publicar y probar en el iPhone en modo avión con una consulta de prueba (Constanza), y luego borrarla
