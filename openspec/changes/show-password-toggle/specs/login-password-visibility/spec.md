## ADDED Requirements

### Requirement: Botón para mostrar u ocultar la contraseña
El campo de contraseña de la pantalla de login SHALL tener un botón dentro del campo que alterne entre mostrar y ocultar lo escrito. Por defecto la contraseña MUST estar oculta.

#### Scenario: Mostrar la contraseña
- **WHEN** Constanza escribe su contraseña y toca el botón 👁
- **THEN** la contraseña se ve en texto normal
- **AND** el cursor sigue en el campo y puede seguir escribiendo

#### Scenario: Ocultar de nuevo
- **WHEN** la contraseña está visible y toca el botón otra vez
- **THEN** la contraseña vuelve a verse con puntos

#### Scenario: El botón no envía el formulario
- **WHEN** toca el botón 👁
- **THEN** no se intenta iniciar sesión

### Requirement: La contraseña vuelve a ocultarse tras cada intento
Después de cada intento de inicio de sesión, correcto o fallido, el campo de contraseña SHALL volver a quedar oculto.

#### Scenario: Contraseña incorrecta
- **WHEN** la contraseña estaba visible y el inicio de sesión falla
- **THEN** el campo se vacía, como hoy, y queda en modo oculto

### Requirement: Accesible y cómodo en el iPhone
El botón SHALL tener un área táctil de al menos 40×40 px y una etiqueta accesible ("Mostrar contraseña" / "Ocultar contraseña") que cambie según el estado.

#### Scenario: Uso con el dedo en el iPhone
- **WHEN** Constanza toca el ojo en la pantalla del iPhone
- **THEN** el toque se reconoce sin tener que apuntar con precisión
