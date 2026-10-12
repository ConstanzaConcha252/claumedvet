## Why

En visitas a domicilio con mala señal, Constanza necesita **anotar** (consultas, vacunas, citas, cobros y pacientes nuevos), no solo consultar. Hoy esos cambios quedan en el teléfono, pero se pierden: al abrir la app con internet, `pullFromCloud()` reemplaza los datos locales con los de la nube antes de subir nada. Tampoco se recuerdan los borrados hechos sin conexión, así que el registro borrado "revive" al sincronizar.

Este cambio depende de `fix-offline-startup`, que hace que la app abra sin internet. Se implementa después de ese.

## What Changes

- La app recuerda en el teléfono que hay **cambios pendientes** cuando no logra subirlos a la nube.
- Al volver internet (al abrir la app o al reconectar con la app abierta), la app **primero sube** los cambios pendientes y solo después descarga de la nube.
- Los borrados hechos sin conexión se guardan en una lista y se envían a Supabase al reconectar.
- Antes de subir registros **nuevos** creados sin conexión, se revisa si ese número de ficha (ID) ya existe en la nube (creado desde otro dispositivo). Si hay choque, no se sube nada automáticamente: se avisa a Constanza y los datos quedan seguros en el teléfono.
- El aviso de modo sin conexión cambia a: "📴 Sin conexión: tus cambios se guardan en este teléfono y se subirán cuando vuelva internet." El indicador de nube muestra cuántos cambios hay pendientes.
- La subida completa sigue enviando un registro por petición, como hoy, pero ahora la app espera a que **todas** terminen, para saber si la sincronización salió bien o quedó pendiente.
- Adjuntar archivos (exámenes y recetas en Storage) sigue requiriendo internet. Eso ya funciona bien hoy: sin conexión muestra un aviso y no cierra el formulario. Solo se verifica, no se cambia.

## Capabilities

### New Capabilities
- `offline-sync`: los cambios y borrados hechos sin conexión se guardan como pendientes y se suben a Supabase al recuperar internet, antes de descargar datos de la nube y con detección de choques de ID.

### Modified Capabilities
- `offline-startup`: se elimina el requisito "Aviso de que los cambios sin conexión pueden perderse", que se reemplaza por "Aviso y estado de pendientes" en `offline-sync`.

## Impact

- `ClauMedVet.html`:
  - `saveDB()` / `syncAllToCloud()`: subida en lote que se puede esperar, y marca de pendientes en `localStorage`;
  - `pushDelete*()`: guardan en una cola los borrados que fallan por red;
  - `startAppAfterLogin()` y el listener `onAuthStateChange`: suben los pendientes antes de `pullFromCloud()`;
  - `renderCloudBadge()`: muestra los pendientes;
  - texto de `#offlineBanner` (creado en `fix-offline-startup`).
- Nuevas claves en `localStorage`: `claudmedvet_pending_v1` (cambios pendientes, borrados en cola e IDs creados sin conexión).
- Seguridad: no cambia RLS. Todas las llamadas siguen pasando por `sbFetch()` con `SB_HEADERS` / `setAuthHeader`. No se sube nada mientras no haya una sesión válida (`authenticated`).
- Comportamiento ya existente que se mantiene: la app sube la base completa del teléfono, así que si se editó **el mismo registro** desde otro dispositivo, gana la versión del último que sube. Se recomienda usar un dispositivo a la vez.
