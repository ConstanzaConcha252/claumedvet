## 1. Implementación

- [x] 1.1 Envolver `#loginPass` en `.pw-wrap` y agregar `<button type="button" class="pw-toggle" id="loginPassToggle">` con `aria-label="Mostrar contraseña"`
- [x] 1.2 CSS: `.pw-wrap{position:relative}`, botón de 40×40 a la derecha y centrado verticalmente, `padding-right` en el input
- [x] 1.3 Funciones `setPasswordVisible(bool)` y `togglePasswordVisibility()`: cambian `type`, el ícono (👁/🙈), `aria-label` y `aria-pressed`
- [x] 1.4 Conectar el botón en el `DOMContentLoaded` existente (click + `pointerdown` con `preventDefault` para no perder el foco)
- [x] 1.5 En `doLogin()`, llamar a `setPasswordVisible(false)` al iniciar el intento
- [x] 1.6 Cambiar el `src` de `<img class="login-logo">` a `./icon-512.png`
- [x] 1.7 Subir el `build` (2 lugares)

## 2. Pruebas

- [x] 2.1 `node --check` del JS del HTML
- [x] 2.2 Navegador local (ancho iPhone): escribir, tocar el ojo y ver el texto; tocar de nuevo y ver puntos; el foco sigue en el campo; el botón no dispara el login; captura de pantalla para Constanza
- [x] 2.3 El logo del login se ve igual al ícono, con y sin conexión (captura)
- [x] 2.4 Login fallido (contra una Supabase falsa) con la contraseña visible: el campo queda vacío y oculto
- [ ] 2.5 Publicar y probar en el iPhone (Constanza)
