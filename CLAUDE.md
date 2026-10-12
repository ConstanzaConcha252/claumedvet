# ClauMedVet — contexto para Claude

## Qué es

App web para gestionar la práctica veterinaria a domicilio de Constanza en Curicó, Chile. Maneja pacientes (con foto), citas, historia clínica y cobros.

- **Sitio publicado:** https://constanzaconcha252.github.io/claumedvet/ClauMedVet.html (GitHub Pages)
- **Repo:** `ConstanzaConcha252/claumedvet`. Es **público**, así que todo lo que se suba aquí lo puede ver cualquiera.
- **Base de datos y login:** Supabase, plan Free. Proyecto `jxhotwoeaozlqtujwodz`, región `sa-east-1`, Postgres 17.6.

## Cómo trabajar con Constanza

- Responder siempre en **español**.
- Ella no escribe código: pide cambios, los revisa y prueba el resultado. Prefiere arreglos directos y código que funcione antes que explicaciones largas.
- Antes de hacer `git commit` o `git push`, mostrarle qué cambió y en qué archivos, en lenguaje simple. Hacer commit solo con su visto bueno.
- Hacer cambios chicos y acotados. No reescribir ni reorganizar `ClauMedVet.html` completo sin que ella lo pida.
- Si una función nueva falla una y otra vez, ella prefiere sacarla antes que seguir depurando sin fin. Ofrecer esa opción.
- Al terminar un cambio técnico (código, RLS, workflows, infraestructura), entregar un resumen corto para el "Historial de cambios" del spec. El spec vive en su Project de claude.ai (`spec-seguridad-y-respaldo.md`), no en este repo.
- En cada cambio publicado a `ClauMedVet.html` o `service-worker.js`, subir el número `build YYYY-MM-DD.N`, que aparece dos veces en el HTML, y decirle a Constanza cuál es, para que confirme en la barra lateral que el iPhone tomó la versión nueva.
- Los cambios de funcionalidad se planifican con OpenSpec: `/opsx:propose`, luego `/opsx:apply` y, cuando ella lo confirma en el iPhone, `/opsx:archive`.
- Probar antes de pedir el visto bueno: sintaxis con `node --check` sobre el JS extraído y, si aplica, en el navegador con `python -m http.server`. Para probar sincronización, usar una **Supabase falsa** que intercepte las llamadas a `*.supabase.co`. **Nunca** escribir datos de prueba en la base real ni usar sus credenciales.

## Estructura

- `ClauMedVet.html`: **toda la app** (HTML + CSS + JS) en un solo archivo, sin build ni dependencias locales.
- `service-worker.js`, `manifest.json`, `icon-192.png`, `icon-512.png`: archivos de la PWA (app instalable en el iPhone).
- `openspec/`: propuestas de cambios (OpenSpec). Los specs vigentes están en `openspec/specs/` y los cambios terminados en `openspec/changes/archive/`.
- `.github/workflows/weekly-backup.yml`: respaldo semanal automático de la base de datos.
- `supabase_fix_rls_v2.sql` y `supabase_fix_storage_rls.sql`: las políticas de seguridad vigentes.
- `supabase_fix_rls.sql`: solo registro histórico del estado anterior, que era inseguro. **No volver a correrlo.**

## Arquitectura de la app

- Supabase se usa vía REST con `sbFetch()`. `saveDB()` guarda local, marca pendiente y llama a `syncAllToCloud()` → `syncNow()`, que sube la base completa del dispositivo (ver "Modo sin conexión"). Los borrados se encolan con `queueDelete()`.
- `localStorage` funciona como caché instantánea. Supabase es la fuente de verdad, pero `pullFromCloud()` (que **reemplaza** lo local) solo se ejecuta después de subir lo pendiente.
- Las tablas son `patients`, `appointments`, `invoices` y `app_config`. En Storage hay dos buckets: `examenes` y `recetas`.
- En la barra lateral hay un indicador de nube (☁️ Sincronizado / 📴 Sin conexión / ⚠️ Error, con "· cambios por subir" cuando corresponde) y un botón para descargar un respaldo en Excel. En el iPhone, la barra superior solo muestra el icono; el texto se ve en el menú lateral.
- Debajo del botón de respaldo, y en la pantalla de login, se muestra `build YYYY-MM-DD.N`.

### Login

- Usa Supabase Auth con el cliente `@supabase/supabase-js@2.117.3` (**versión fija**), cargado vía CDN (jsdelivr) con `crossorigin="anonymous"`. Si se cambia la versión, hay que cambiar también `SUPABASE_JS_URL` en `service-worker.js`: deben ser exactamente la misma URL.
- Si la librería no carga, `sbAuth` queda en `null` y el login muestra "Se necesita conexión a internet para abrir ClauMedVet por primera vez".
- `doLogin()` llama a `sbAuth.auth.signInWithPassword({ email, password })`.
- `doLogout()` llama a `sbAuth.auth.signOut()`.
- La sesión se maneja con `sbAuth.auth.getSession()` y `onAuthStateChange(...)`.
- `setAuthHeader(accessToken)` actualiza `SB_HEADERS.Authorization`. Sin sesión usa la publishable key; con sesión usa el `access_token` del usuario.
- Las subidas a Storage (`uploadExamFile`, `uploadRecetaFile`) también usan esos headers dinámicos.
- El auto-registro está desactivado en Supabase. Existe un solo usuario, creado a mano en el dashboard.

### PWA y modo sin conexión

Constanza usa la app instalada en el iPhone ("Agregar a pantalla de inicio") y la usa en terreno con mala señal. Specs: `openspec/specs/offline-startup` y `openspec/specs/offline-sync`.

- **Service worker** (caché `claumedvet-shell-v2`): los archivos propios van con "red primero" y `cache: 'no-cache'`, para no usar la copia de 10 minutos de GitHub Pages. La librería `supabase-js` va con "caché primero". **Nunca** guarda respuestas de `*.supabase.co`: los datos clínicos no entran a esa caché.
- **Arranque sin red:** si hay sesión guardada (`hasStoredSession()`) y `getSession()` no responde en 1,5 s (sin red) o 4 s (señal mala), abre con `startAppOffline()` usando los datos locales (`offlineMode = true`). Supabase reintenta renovar el token hasta ~30 s sin red; por eso existe ese temporizador.
- **Cambios pendientes:** se guardan en `localStorage['claudmedvet_pending_v1']` con `dirty`/`rev`, `deletes` (borrados en cola) y `created` (IDs nuevos sin subir, generados con `newId(tabla)`).
- **Orden obligatorio:** `syncThenPull()` sube primero (`syncNow()`) y solo si sale bien llama a `pullFromCloud()`. No llamar a `pullFromCloud()` directo cuando puede haber pendientes, porque se perderían.
- **`syncNow()`** no corre dos veces a la vez. Pasos: borrados → revisa choques de ID en `created` → upsert de todo → contadores `next_*_id` con `max(local, nube)`. Solo sube con sesión real (`hasUserSession()`), nunca con la publishable key.
- **Choque de ID** (el mismo número creado en otro dispositivo): no sube nada, avisa una vez por sesión y la sincronización queda detenida hasta resolverlo a mano.
- **Reconexión:** `checkReconnect()` corre cada 15 s, con los eventos `online`/`offline` y al volver a la app. En el iPhone, esos eventos no siempre llegan, por eso existe el intervalo.
- Ya **no** se cargan datos de ejemplo (`initSampleData`) cuando falla la conexión, porque terminarían subiéndose a la base real.
- Adjuntar exámenes y recetas (Storage) sigue requiriendo internet.

## Reglas de seguridad (no romper)

- **Nunca** escribir contraseñas, tokens, la cadena de conexión de la base ni la service_role key en ningún archivo del repo. La única key que puede ir en el HTML es la **publishable key** (`sb_publishable_...`), que es pública por diseño.
- Las políticas RLS de las 4 tablas y de los 2 buckets están restringidas a `authenticated`. **Nunca** crear ni proponer políticas para el rol `anon`. Antes de esta corrección, el login era decorativo y cualquiera podía leer o modificar los datos clínicos.
- Toda llamada nueva a Supabase debe pasar por los headers dinámicos (`SB_HEADERS` / `setAuthHeader`), nunca por headers armados con la key fija.
- No subir a este repo respaldos, dumps ni exportaciones con datos de pacientes. Esos van solo al repo privado `claumedvet-backups`.

## Respaldo semanal (GitHub Actions)

- **Cuándo corre:** cron `0 12 * * 1` (lunes 08:00 en Chile continental) y también a mano con `workflow_dispatch`.
- **Dónde corre:** dentro del contenedor `postgres:17`, para que la versión de `pg_dump` coincida con la de Supabase.
- **Pasos:**
  1. `pg_dump`, con 3 intentos y 2 minutos de espera entre cada uno.
  2. Instala `git` y `curl`.
  3. Hace un ping a `/rest/v1/` para evitar que Supabase pause el proyecto por inactividad. Tiene `--max-time 30`, `timeout-minutes: 2` y `continue-on-error`.
  4. Hace commit y push del `.sql.gz` al repo privado `claumedvet-backups`.
- **Secrets:** `SUPABASE_DB_URL` (Session pooler), `BACKUP_REPO_TOKEN` y `BACKUP_REPO`.
- Si en algún momento se sube la versión mayor de Postgres en Supabase, hay que cambiar también la imagen `postgres:17` del workflow.

## Problemas conocidos y cómo se resolvieron

- **Abrir el HTML como `file://`:** el navegador bloquea los `fetch` a Supabase. Para probar hay que usar un servidor local (por ejemplo `python -m http.server`) o GitHub Pages.
- **Headers de Supabase:** hacen falta los dos, `Authorization: Bearer` y `apikey`. Si falta alguno, aparecen errores de CORS o 401.
- **Errores de sintaxis en JS:** uno solo rompe toda la app sin aviso visible. Lo primero es revisar la consola del navegador.
- **Comillas dentro de template literals:** cuando se genera HTML dinámico, escaparlas mal es una fuente recurrente de bugs. Hay que revisar con cuidado los `onclick` armados con strings.
- **Conexión directa a la base:** solo funciona por IPv6, y los runners de GitHub no tienen IPv6. Hay que usar el **Session pooler** (`aws-1-sa-east-1.pooler.supabase.com`). Ojo con el dominio: el pooler es `supabase.com` y la conexión directa es `supabase.co`.
- **`EAUTHQUERY ... connection to database not available`:** es una indisponibilidad momentánea, y la cubren los reintentos. Si se repite, revisar si el proyecto aparece "Paused" en el dashboard.
- **`The job was not acquired by Runner` / `Internal server error`:** es una falla de GitHub, no del workflow. Se resuelve relanzando a mano.
- **El iPhone sigue mostrando la versión antigua:** hay que abrir la app con internet, cerrarla por completo y volver a abrirla (una vez para el service worker y otra para la página), y después revisar el `build`. Si no se actualiza, borrar el ícono y volver a "Agregar a pantalla de inicio" desde Safari. No se pierden datos, porque están en la nube.
- **Eventos `online`/`offline` en el iPhone:** en la PWA instalada no siempre llegan. Cualquier lógica de reconexión tiene que tener también un intervalo, como `checkReconnect()`.
- **Chrome headless en Windows con el perfil en una ruta larga** (por ejemplo, el scratchpad): `caches.open()` falla con "Unexpected internal error". Usar un `userDataDir` corto, como `C:/Users/HP/AppData/Local/Temp/cmvt-*`.
- **Pausa del plan Free de Supabase:** el proyecto se pausa tras unos 7 días sin actividad en la API. `pg_dump` no cuenta como actividad; por eso existe el ping.

## Pendientes conocidos

- El token `BACKUP_REPO_TOKEN` vence en una fecha que no quedó registrada. Si el respaldo empieza a fallar por autenticación en git, revisar eso primero.
- Verificar que la corrida del lunes 19-oct-2026 salga verde, porque `ubuntu-latest` migra a Ubuntu 26 ese día.
- GitHub desactiva los workflows programados de repos públicos tras 60 días sin commits.
