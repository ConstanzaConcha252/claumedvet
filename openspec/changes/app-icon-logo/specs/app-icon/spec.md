## ADDED Requirements

### Requirement: Ícono de la app con el logo de ClauMedVet
Los íconos de la app (`apple-touch-icon.png` de 180×180, `icon-192.png` e `icon-512.png`) SHALL mostrar el dibujo del logo de ClauMedVet (perro y gato junto a una casa con corazón), el mismo de la barra lateral, completo y sin recortes, con todas las líneas en blanco sobre fondo turquesa `#1a8fa0`.

#### Scenario: Agregar a pantalla de inicio en el iPhone
- **WHEN** Constanza abre el sitio en Safari y elige Compartir → Agregar a pantalla de inicio
- **THEN** la vista previa y el ícono en la pantalla de inicio muestran el logo de ClauMedVet

#### Scenario: Ícono recortado por el sistema
- **WHEN** un sistema recorta el ícono con esquinas redondeadas o en círculo (iPhone, Android "maskable")
- **THEN** el dibujo del logo queda completo dentro del área visible, sin cortar el perro, el gato ni la casa

### Requirement: Ícono del iPhone en tamaño nativo
`ClauMedVet.html` SHALL declarar `<link rel="apple-touch-icon">` apuntando a un PNG de 180×180, sin transparencia.

#### Scenario: Ícono nítido
- **WHEN** el iPhone genera el ícono de la pantalla de inicio
- **THEN** usa el PNG de 180×180, sin bordes negros ni fondo transparente

### Requirement: Ícono disponible sin conexión
El service worker SHALL incluir `apple-touch-icon.png` en los archivos que guarda, igual que los otros íconos.

#### Scenario: Caché actualizada
- **WHEN** el teléfono abre la app con internet después del despliegue
- **THEN** el service worker nuevo guarda `apple-touch-icon.png` en `claumedvet-shell-v3` y borra la caché anterior
