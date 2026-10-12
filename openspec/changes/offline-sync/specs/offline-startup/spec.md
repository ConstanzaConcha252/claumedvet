## REMOVED Requirements

### Requirement: Aviso de que los cambios sin conexión pueden perderse
**Reason**: Con `offline-sync`, los cambios hechos sin conexión ya no se pierden: se guardan como pendientes y se suben al volver internet. El aviso cambia de texto.
**Migration**: Reemplazado por el requisito "Aviso y estado de pendientes" de la capacidad `offline-sync`, que conserva los escenarios de reconexión.
