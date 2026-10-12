## Context

Así funciona la sincronización hoy en `ClauMedVet.html`:

- `saveDB()` guarda en `localStorage` (`claudmedvet_v2`) y llama a `syncAllToCloud()`. Esa función dispara, **sin esperar el resultado**, un upsert por cada paciente, cita y cobro, más `pushConfig()` (`next_*_id` y `tarifas`). Es decir, cada guardado sube la base completa del dispositivo.
- `pushDeletePatient/Appt/Invoice(id)` hacen un DELETE y, si falla, solo lo registran en la consola.
- `startAppAfterLogin()` ejecuta `pullFromCloud()`, que **reemplaza** `DB.patients/appointments/invoices` y los `next*Id` con lo que hay en la nube.
- Los IDs nuevos salen de `DB.nextId++`, `DB.nextAid++` y `DB.nextInvId++` (líneas ~2003, ~2420, ~2522 y ~2674).
- Los adjuntos (`uploadExamFile` y `uploadRecetaFile`) ya fallan con un `alert` claro y no cierran el formulario.

`fix-offline-startup` (prerrequisito) agrega `offlineMode`, `startAppOffline()`, `#offlineBanner` y el manejo de `onAuthStateChange` al reconectar.

## Goals / Non-Goals

**Goals:**
- Que ningún cambio hecho sin conexión se pierda al volver internet.
- Subir los pendientes **antes** de cualquier `pullFromCloud()`.
- Que los borrados hechos sin conexión se apliquen en la nube.
- Detectar choques de ID en registros nuevos y frenar en vez de pisar datos.

**Non-Goals:**
- Combinar cambios campo por campo cuando el mismo registro se editó en dos dispositivos. Se mantiene "gana el último que sube", como hoy.
- Subir adjuntos sin conexión (cola de archivos).
- Resolver choques de ID automáticamente (renumerar). Se detectan y se avisa; la resolución es manual.
- Cambiar RLS o el esquema de la base.

## Decisions

### 1. Estado de pendientes en `localStorage`
Clave `claudmedvet_pending_v1`:
```js
{ dirty: false, rev: 0,
  deletes: { patients: [], appointments: [], invoices: [] },
  created: { patients: [], appointments: [], invoices: [] } }
```
- `dirty` y `rev`: `saveDB()` deja `dirty = true` y aumenta `rev` **antes** de intentar subir. Una sincronización exitosa solo limpia `dirty` si `rev` no cambió mientras corría, para no perder un guardado hecho entre medio.
- `created`: en los 4 puntos donde se crea un ID se agrega a la lista que corresponde. Se usa para detectar choques.
- `deletes`: borrados que fallaron por red.
- Se elige `localStorage` porque es el mismo mecanismo que ya usa la app para la caché, y el volumen es muy chico.

### 2. `syncNow()`: subida que se puede esperar y que no corre dos veces a la vez
Reemplaza el interior de `syncAllToCloud()`. `saveDB()` lo sigue llamando sin esperar, igual que hoy.
1. Si no hay sesión válida (por ejemplo, en `offlineMode`, donde `SB_HEADERS` lleva la publishable key), no hace nada y deja `dirty`.
2. Si ya hay una ejecución en curso, marca `rerun = true` y devuelve la misma promesa. Al terminar, si `rerun`, corre otra vez. Así dos guardados seguidos no se pisan ni generan falsos choques.
3. Toma una copia (snapshot) de `rev`, `created` y `deletes`.
4. **Borrados:** envía cada DELETE de la cola y saca de la cola los que salen bien. Borrar en la nube un ID que nunca se subió no da error.
5. **Choques:** para cada tabla con IDs en `created`, hace `GET <tabla>?select=id&id=in.(…)`. Si vuelve alguno, detiene todo: estado `error`, `lastCloudErrorDetail` explica el choque y se muestra **una vez por sesión** un `alert` que sugiere descargar el respaldo JSON. No sube nada.
6. **Upserts:** por tabla, hace `Promise.all` de upserts por registro con los mismos `patientToRow/apptToRow/invoiceToRow` y headers de hoy. Cuando una tabla completa sale bien, saca de `created` los IDs del snapshot de esa tabla. Así un fallo a medias no deja falsos choques en el siguiente intento.
7. **Config:** lee de la nube `next_*_id` y sube `max(local, nube)`, para que un teléfono atrasado no baje el contador y provoque choques futuros.
8. Si todo sale bien y `rev` no cambió: `dirty = false`, estado `online`. Si algo falla: se mantiene `dirty` y el estado queda `offline` (red) o `error` (API).

Se mantiene un upsert por registro, en vez de un POST en lote por tabla, porque los pacientes llevan la foto como data URL y un lote podría superar el límite de tamaño de petición. Es la misma cantidad de datos que se sube hoy en cada guardado.

### 3. Orden al reconectar o al arrancar
- `startAppAfterLogin()`: si `pending.dirty`, hace `await syncNow()`. Solo si sale bien llama a `pullFromCloud()`. Si falla, se queda con los datos locales y no ejecuta `initSampleData()`.
- `onAuthStateChange`: además del manejo de `fix-offline-startup`, ante `SIGNED_IN` o `TOKEN_REFRESHED` con `pending.dirty`, ejecuta `syncNow()` y luego `pullFromCloud()`.
- `window.addEventListener('online', …)`: si hay sesión y `dirty`, ejecuta `syncNow()`. Si el token venció, fallará con 401 y se reintentará cuando `supabase-js` lo renueve (`TOKEN_REFRESHED`).

### 4. Borrados
`pushDelete*()` agregan el ID a `pending.deletes.<tabla>` cuando el error no es `isApiError` (falla de red), y marcan `dirty`. Si el ID estaba en `created` (nunca se subió), se saca de `created`.

### 5. Interfaz
- `#offlineBanner`: el texto cambia a "📴 Sin conexión: tus cambios se guardan en este teléfono y se subirán cuando vuelva internet."
- `renderCloudBadge()`: si `pending.dirty`, agrega " · cambios por subir" al texto.

### 6. Ajustes hechos durante la implementación
- **Sin datos de ejemplo automáticos:** `startAppAfterLogin()` ya no llama a `initSampleData()` cuando falla la conexión. Con los pendientes persistentes, esos pacientes de ejemplo se habrían subido a la base real al reconectar.
- **IDs nuevos:** se usa el helper `newId(tabla)` en los 4 puntos de creación. Genera el ID y lo anota en `created`.
- **Borrados:** `pushDelete*()` siempre encolan el borrado y llaman a `syncNow()`, no solo cuando falla. Así no se pierden borrados hechos en `offlineMode`, donde no hay token de usuario y el DELETE fallaría con 401 en vez de un error de red.
- **Reintento:** se reutiliza `checkReconnect()` de `fix-offline-startup` (cada 15 s, `online` y `visibilitychange`). Ahora también corre si `hasPending()` y usa `syncThenPull()`.
- **Cerrar sesión con pendientes:** el `confirm` avisa que hay cambios sin subir; se subirán la próxima vez que se entre con internet en ese teléfono.
- **Después de un choque, la sincronización queda detenida:** mientras haya un ID en `created` que choca, cada intento vuelve a detectarlo y no sube nada. Es intencional, para no pisar datos; hay que resolverlo a mano.

## Risks / Trade-offs

- **Mismo registro editado en dos dispositivos:** gana el último que sube, igual que hoy. → Recomendación de uso: un dispositivo a la vez. Queda documentado.
- **Choque de ID (registro nuevo en dos dispositivos):** se detecta y se frena, pero la resolución es manual. → Es poco probable con una sola usuaria. Si pasa, se descarga el respaldo y se corrige con ayuda.
- **Falso positivo de choque:** si un upsert de una tabla salió bien pero la respuesta se perdió por la red, el ID queda en `created` y el próximo intento detecta un "choque" consigo mismo. → Es raro. Si ocurre, el aviso lo explica y se puede limpiar a mano. Como mejora futura, se podría comparar el contenido.
- **Espacio en `localStorage`:** si el teléfono se queda sin espacio, `saveLocalDB` guarda sin fotos; una foto tomada sin conexión podría no persistir. Ya pasa hoy y no cambia.
- **Más tráfico al reconectar:** no hay cambio real, porque hoy cada guardado ya sube la base completa.

## Migration Plan

1. Implementar y publicar `fix-offline-startup` primero, y probarlo en el iPhone.
2. Implementar este cambio, probarlo en el escritorio con DevTools "Offline" y publicarlo.
3. En el iPhone: abrir la app con internet una vez y luego probar el flujo en modo avión.

Rollback: revertir el commit. La clave `claudmedvet_pending_v1` queda en el teléfono sin efecto. Antes de revertir, sincronizar con internet para no dejar pendientes sin subir.

## Open Questions

- Ninguna bloqueante.
