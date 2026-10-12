## ADDED Requirements

### Requirement: Registrar cambios pendientes
Cuando un guardado no se pueda subir a Supabase por falta de conexión, la app SHALL marcar en `localStorage` que hay cambios pendientes. La marca MUST persistir aunque se cierre la app.

#### Scenario: Anotar una consulta sin internet
- **WHEN** Constanza registra una consulta sin conexión
- **THEN** la consulta queda guardada en el teléfono
- **AND** la app marca que hay cambios pendientes
- **AND** el indicador de nube muestra que hay cambios por subir

#### Scenario: Cerrar y abrir la app sin internet
- **WHEN** se cierra la app con cambios pendientes y se vuelve a abrir sin conexión
- **THEN** los cambios siguen visibles y siguen marcados como pendientes

### Requirement: Subir pendientes antes de descargar
Al recuperar conexión con una sesión válida, la app SHALL subir todos los cambios pendientes a Supabase y MUST NOT ejecutar `pullFromCloud()` hasta que esa subida termine bien. Si la subida falla, la app MUST conservar los datos locales y la marca de pendientes.

#### Scenario: Abrir la app con internet y pendientes
- **WHEN** la app abre con internet y hay cambios pendientes
- **THEN** primero sube los datos locales
- **AND** solo después descarga desde la nube
- **AND** los cambios hechos sin conexión siguen visibles y quedan guardados en Supabase

#### Scenario: Vuelve la señal con la app abierta
- **WHEN** la app está en modo sin conexión con cambios pendientes y vuelve internet
- **THEN** al renovarse la sesión, la app sube los pendientes, luego sincroniza y muestra "☁️ Sincronizado"

#### Scenario: La subida falla a medias
- **WHEN** la subida de pendientes falla (red o error de Supabase)
- **THEN** la app no descarga de la nube, los datos locales quedan intactos y los pendientes se reintentan en la próxima oportunidad

### Requirement: Borrados sin conexión
Cuando un borrado no se pueda enviar a Supabase por falta de conexión, la app SHALL guardarlo en una cola persistente y SHALL enviarlo antes de descargar desde la nube.

#### Scenario: Borrar una cita sin internet
- **WHEN** Constanza borra una cita sin conexión y después vuelve internet
- **THEN** la cita se borra también en Supabase
- **AND** no reaparece después de sincronizar

### Requirement: Detección de choque de IDs en registros nuevos
Para los pacientes, citas y cobros creados sin conexión, antes de subirlos la app SHALL comprobar si su ID ya existe en Supabase. Si alguno existe, la app MUST NOT subir los pendientes y SHALL avisar a Constanza, conservando los datos locales.

#### Scenario: Paciente nuevo sin choque
- **WHEN** se crea un paciente sin conexión y su ID no existe en la nube
- **THEN** se sube normalmente al reconectar

#### Scenario: Choque con un registro creado desde otro dispositivo
- **WHEN** se crea una cita sin conexión con el ID 57 y, mientras tanto, en el computador se creó otra cita con el ID 57
- **THEN** al reconectar la app no sube nada
- **AND** muestra un aviso explicando el choque y sugiriendo descargar el respaldo JSON
- **AND** los datos locales y la marca de pendientes se conservan

### Requirement: Aviso y estado de pendientes
En modo sin conexión, el aviso SHALL decir que los cambios se guardan en el teléfono y se subirán al volver internet. El indicador de nube SHALL mostrar cuando hay cambios pendientes.

#### Scenario: Aviso en modo sin conexión
- **WHEN** la app está sin conexión
- **THEN** el aviso dice "📴 Sin conexión: tus cambios se guardan en este teléfono y se subirán cuando vuelva internet."

#### Scenario: Pendientes visibles
- **WHEN** hay cambios pendientes
- **THEN** el indicador de nube lo muestra (por ejemplo, "📴 Sin conexión · cambios por subir")

#### Scenario: Aviso desaparece al reconectar
- **WHEN** vuelve la conexión, Supabase renueva la sesión y los pendientes se suben bien
- **THEN** el aviso desaparece, el token se actualiza vía `setAuthHeader` y la app sincroniza con la nube

#### Scenario: Reconexión sin cerrar la app en el iPhone
- **WHEN** la app instalada está abierta sin conexión y vuelve internet, aunque el navegador no envíe el evento `online`
- **THEN** en 15 segundos o menos la app renueva la sesión, sube los pendientes, sincroniza y muestra "☁️ Sincronizado" sin que haya que cerrarla

### Requirement: Archivos adjuntos requieren conexión
Al intentar adjuntar un examen o receta sin conexión, la app SHALL mostrar un mensaje claro de que adjuntar archivos requiere internet, sin perder el resto del formulario.

#### Scenario: Adjuntar receta sin internet
- **WHEN** Constanza registra una consulta con una receta adjunta sin conexión
- **THEN** la app avisa que los archivos requieren internet
- **AND** no se pierde lo escrito en el formulario
