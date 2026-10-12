## ADDED Requirements

### Requirement: Librería de login disponible sin internet
El service worker SHALL guardar una copia de la librería `supabase-js` (URL con versión exacta) y SHALL entregarla desde la caché cuando no haya conexión. El service worker MUST NOT guardar en caché respuestas de la API de Supabase (`*.supabase.co`) ni de ningún otro dominio externo.

#### Scenario: Abrir la app sin internet después de haberla usado con conexión
- **WHEN** la app ya se abrió al menos una vez con internet en ese dispositivo
- **AND** el dispositivo no tiene conexión
- **THEN** la librería `supabase-js` se carga desde la caché y el script principal de la app se ejecuta sin errores

#### Scenario: Llamadas a la API de Supabase no se guardan
- **WHEN** la app hace un `fetch` a `https://jxhotwoeaozlqtujwodz.supabase.co/...`
- **THEN** el service worker no lo intercepta ni guarda la respuesta en la caché

### Requirement: Mensaje claro si la librería no está disponible
Si la librería `supabase-js` no se pudo cargar, la app SHALL mostrar en la pantalla de login un mensaje que diga que se necesita internet para abrirla, en vez de detenerse sin aviso.

#### Scenario: Primera apertura sin internet
- **WHEN** la app se abre sin internet y la librería no está en la caché
- **THEN** la pantalla de login muestra "Se necesita conexión a internet para abrir ClauMedVet por primera vez" (o texto equivalente)
- **AND** no aparece un error de JavaScript que detenga el resto del script

### Requirement: Modo consulta sin conexión con sesión guardada
Cuando no haya conexión y exista una sesión de Supabase guardada en el dispositivo, la app SHALL abrir directamente con los datos de la caché local (`localStorage`), aunque el token de acceso haya vencido. Si no existe sesión guardada, la app MUST mostrar la pantalla de login como hoy.

#### Scenario: Sin internet, sesión guardada y token vencido
- **WHEN** Constanza abre la app sin internet
- **AND** no cerró sesión la última vez
- **AND** el token de acceso venció
- **THEN** la app abre mostrando pacientes, agenda y cobros guardados localmente
- **AND** el indicador de nube muestra "📴 Sin conexión"

#### Scenario: Sin internet y sin sesión guardada
- **WHEN** la app se abre sin internet
- **AND** no hay sesión guardada (se cerró sesión antes)
- **THEN** la app muestra la pantalla de login y no muestra datos de pacientes

#### Scenario: Con internet
- **WHEN** la app se abre con conexión
- **THEN** el arranque funciona igual que hoy (renueva el token si hace falta y sincroniza con Supabase)

### Requirement: Aviso de que los cambios sin conexión pueden perderse
Mientras la app esté en modo sin conexión, SHALL mostrar un aviso visible indicando que los cambios hechos sin internet no se guardan en la nube y pueden perderse al reconectar.

#### Scenario: Aviso visible en modo sin conexión
- **WHEN** la app abre en modo sin conexión
- **THEN** se muestra un aviso visible en pantalla mientras no haya conexión

#### Scenario: Aviso desaparece al reconectar
- **WHEN** vuelve la conexión y Supabase renueva la sesión
- **THEN** el aviso desaparece, el token se actualiza vía `setAuthHeader` y la app sincroniza con la nube

#### Scenario: Reconexión sin cerrar la app en el iPhone
- **WHEN** la app instalada está abierta sin conexión y vuelve internet, aunque el navegador no envíe el evento `online`
- **THEN** en 15 segundos o menos la app renueva la sesión, sincroniza y muestra "☁️ Sincronizado" sin que haya que cerrarla

### Requirement: Teléfonos ya instalados reciben la actualización
El service worker SHALL usar un nombre de caché nuevo para que los dispositivos con la PWA ya instalada descarguen la versión actualizada y borren la caché anterior.

#### Scenario: Actualización en iPhone con la app instalada
- **WHEN** Constanza abre la app instalada con internet después del despliegue
- **THEN** el nuevo service worker se instala, borra `claumedvet-shell-v1` y guarda la librería en `claumedvet-shell-v2`
