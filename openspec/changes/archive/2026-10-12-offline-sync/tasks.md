## 0. Prerrequisito

- [x] 0.1 Confirmar que `fix-offline-startup` está implementado y probado (existen `offlineMode`, `startAppOffline()` y `#offlineBanner`)

## 1. Estado de pendientes

- [x] 1.1 Agregar `loadPending()` y `savePending()` para `claudmedvet_pending_v1` (`dirty`, `rev`, `deletes`, `created`), con `try/catch` igual que el resto de los accesos a `localStorage`
- [x] 1.2 En `saveDB()`, marcar `dirty = true` y `rev++` antes de sincronizar
- [x] 1.3 (Implementado con el helper `newId(tabla)`.) Registrar el nuevo ID en `pending.created` en los 4 lugares donde se crean registros (paciente ~2003, cita ~2420, cobro ~2522 y ~2674)

## 2. Sincronización que se puede esperar

- [x] 2.1 Crear `syncNow()` con ejecución única (`inFlight` + `rerun`) y salida temprana si no hay sesión válida
- [x] 2.2 Paso de borrados: enviar la cola `deletes` y sacar los que salen bien
- [x] 2.3 Paso de choques: `GET ?select=id&id=in.(…)` por tabla para `created`; si hay coincidencias, detener, estado `error`, detalle y `alert` una vez por sesión
- [x] 2.4 Paso de upserts: `Promise.all` por tabla y, al terminar bien cada tabla, sacar de `created` los IDs del snapshot de esa tabla
- [x] 2.5 Paso de config: leer `next_*_id` de la nube y subir `max(local, nube)` junto con `tarifas`
- [x] 2.6 Al terminar: limpiar `dirty` solo si `rev` no cambió; actualizar `cloudStatus` y `renderCloudBadge()`
- [x] 2.7 Hacer que `syncAllToCloud()` llame a `syncNow()` sin esperar, para que los llamados existentes sigan funcionando

## 3. Borrados sin conexión

- [x] 3.1 En `pushDeletePatient/Appt/Invoice`, si falla por red, agregar a `pending.deletes`, marcar `dirty` y sacar el ID de `created` si estaba

## 4. Orden subir → descargar

- [x] 4.1 `startAppAfterLogin()`: si `pending.dirty`, hacer `await syncNow()` y solo si sale bien llamar a `pullFromCloud()`; si falla, no llamar a `initSampleData()`
- [x] 4.2 `onAuthStateChange`: ante `SIGNED_IN` o `TOKEN_REFRESHED` con `dirty`, ejecutar `syncNow()` y luego `pullFromCloud().then(renderAll)`
- [x] 4.3 Agregar el listener `window 'online'` que ejecuta `syncNow()` si hay sesión y `dirty`

## 5. Interfaz

- [x] 5.1 Cambiar el texto de `#offlineBanner` a "📴 Sin conexión: tus cambios se guardan en este teléfono y se subirán cuando vuelva internet."
- [x] 5.2 En `renderCloudBadge()`, agregar " · cambios por subir" cuando `pending.dirty`

## 6. Pruebas (escritorio con `python -m http.server` y DevTools)

- [x] 6.1 Consola sin errores al cargar; con internet, crear, editar y borrar funcionan como antes y no queda `dirty`
- [x] 6.2 (Las pruebas 6.2–6.7 se hicieron con una Supabase falsa en memoria, interceptando todas las llamadas; nada tocó la base real. Se probaron consulta, vacuna, cita nueva y borrado de cobro; paciente y cobro nuevos usan el mismo `newId()`, pero no se probaron por separado. El borrado probado fue de un cobro, no de una cita: es el mismo `queueDelete()`.) Offline: registrar consulta, vacuna, cita, cobro y paciente nuevo; el indicador muestra "cambios por subir"
- [x] 6.3 Recargar offline: los cambios siguen y siguen pendientes
- [x] 6.4 Volver "Online" con la app abierta: se suben solos y, al revisar en el dashboard de Supabase, están todos
- [x] 6.5 Repetir offline, cerrar la pestaña, volver online y abrir: se suben antes de descargar y nada se pierde
- [x] 6.6 Borrar una cita offline y reconectar: no reaparece y en Supabase ya no existe
- [x] 6.7 Choque: crear una cita offline en una pestaña y otra con el mismo ID desde otra ventana con internet; al reconectar aparece el aviso, no se sube nada y los datos locales siguen
- [x] 6.8 (Verificado leyendo el código: `uploadRecetaFile` y `uploadExamFile` no se tocaron; ante un error muestran `alert` y hacen `return` sin cerrar el modal.) Adjuntar receta y examen offline: aparece el aviso existente y el formulario no se cierra
- [x] 6.9 (Confirmado por Constanza en el iPhone con build 2026-10-11.5: consulta hecha en modo avión se subió sola al volver la señal.) Publicar y probar en el iPhone en modo avión con una consulta de prueba (Constanza), y luego borrarla
