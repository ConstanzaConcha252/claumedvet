# ClauMedVet — Sistema de Gestión Veterinaria

Aplicación web para la gestión diaria de una clínica veterinaria: pacientes, agenda, cobros y recordatorios de vacunas con envío de WhatsApp. Pensada para uso en Curicó, funciona en computador, tablet y celular.

> ⚠️ Este documento es de acceso abierto. No contiene contraseñas, llaves, URLs de bases de datos ni ningún dato que permita acceder al sistema o modificarlo. Esa información se mantiene aparte, fuera de este archivo.

## Características principales

- **Inicio (Dashboard):** resumen del día — pacientes registrados, vacunas urgentes, citas de hoy y cobros pendientes.
- **Pacientes:** ficha completa por paciente (foto, especie, raza, peso, fecha de nacimiento con edad calculada automáticamente en años y meses, tutor, teléfono, email, direcciones), con historial de consultas, vacunas y cobros.
- **Agenda:** citas organizadas por día, con navegación hacia adelante/atrás (flechas o selector de fecha), filtros de "Próximos 7 días" y "Pendientes", y botón para enviar confirmación de la cita por WhatsApp.
- **Cobros:** boleteo simple por paciente con ítems, precios, pagos parciales, gráficos de facturación semanal y de los últimos 12 meses.
- **Recordatorios de vacunas:** alertas automáticas cuando una vacuna está vencida o próxima a vencer (dentro de 30 días), con botón para enviar un recordatorio pre-escrito por WhatsApp al tutor.
- **Sincronización en la nube:** los datos se guardan en el dispositivo y además se respaldan en una base de datos externa, para tener acceso desde más de un equipo.
- **Respaldo manual:** botón "⬇ Descargar respaldo" en el menú lateral, que descarga toda la información en un archivo.
- **Responsive:** el menú lateral se convierte en un panel deslizable (☰) en celular y tablet.

## Acceso al sistema

El sistema requiere usuario y contraseña para entrar. Esas credenciales **no están documentadas aquí** por seguridad — si necesitas conocerlas, recuperarlas o cambiarlas, consulta directamente con quien administra el proyecto.

## Cómo enviar recordatorios y confirmaciones por WhatsApp

No hay envío 100% automático — por ahora eso requeriría contratar un servicio de mensajería empresarial (con costos y verificación de negocio). En su lugar, la app arma el mensaje y abre WhatsApp con el número y el texto ya listos; solo falta tocar "Enviar":

- **Recordatorio de vacuna:** aparece en "Recordatorios" y también en la ficha del paciente → pestaña Vacunas.
- **Confirmación de cita:** aparece junto a cada cita pendiente en la Agenda ("📱 Confirmar").

Si un paciente o una cita no tiene un teléfono válido guardado, en vez del botón aparece "📵 Sin tel." como aviso.

## Sobre los datos

La app guarda la información localmente en el dispositivo y la sincroniza con un servicio externo de base de datos para tener respaldo entre equipos. Los detalles de configuración de esa conexión no se incluyen en este documento.

Para pacientes se guarda su fecha de nacimiento y la edad se calcula sola (años y meses); los pacientes cargados antes de esta función siguen mostrando una edad aproximada hasta que se les agregue la fecha real.

## Estructura del proyecto

Todo el proyecto vive en **un solo archivo** que incluye la interfaz completa y su lógica. No requiere instalación ni servidor propio: se abre directamente en el navegador. Esto lo hace fácil de compartir y actualizar, pero también implica que quien reciba ese archivo puede ver su código — por eso ese archivo (a diferencia de este README) no debe compartirse públicamente ni subirse a sitios abiertos.

## Limitaciones conocidas

- El inicio de sesión es una validación simple, no un sistema de cuentas con roles ni recuperación de contraseña.
- El envío de WhatsApp requiere acción manual (tocar "Enviar"); no hay disparo automático sin intervención humana.
- Si se usan dos dispositivos sin conexión al mismo tiempo y ambos registran cambios antes de sincronizar, puede haber conflictos de datos.
- Las fotos de pacientes muy grandes (más de 2MB) se rechazan al subirlas.

## Historial de cambios recientes

- Diseño responsive para celular y tablet (menú deslizable, tablas y gráficos con scroll).
- Validación de teléfono chileno con prefijo fijo.
- Botón de editar consulta en el historial del paciente.
- Foto de paciente: vista ampliada al tocarla, edición separada con botón de cámara.
- Navegación por fecha en la Agenda (antes solo mostraba el día actual).
- Recordatorios de vacunas y confirmación de citas por WhatsApp.
- Fecha de nacimiento con cálculo automático de edad, compatible con registros antiguos.
- Listado desplegable de vacunas frecuentes al registrar una vacuna.

La versión actual se identifica con un número de "build" visible en la pantalla de inicio de sesión y al pie del menú lateral — útil para confirmar que estás viendo la versión más reciente y no una copia guardada anteriormente.

## Posibles mejoras futuras

- Recordatorios automáticos sin intervención manual.
- Cálculo automático de la próxima fecha de vacuna según edad (mensual en cachorros, anual en adultos).
- Roles de usuario (por ejemplo, recepción vs. veterinario) con permisos distintos.
- Exportar reportes de facturación a Excel o PDF.
