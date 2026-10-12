## ADDED Requirements

### Requirement: Logo del login igual al ícono de la app
La pantalla de login SHALL mostrar como logo la misma imagen del ícono de la app (`icon-512.png`: líneas blancas sobre turquesa `#1a8fa0`), y MUST verse también sin conexión.

#### Scenario: Abrir el login
- **WHEN** Constanza abre la app sin sesión iniciada
- **THEN** el logo del login es el mismo dibujo y colores que el ícono de la pantalla de inicio

#### Scenario: Login sin internet
- **WHEN** la app se abre sin conexión después de haberse usado con internet
- **THEN** el logo del login se ve igual, porque `icon-512.png` está en la caché del service worker
