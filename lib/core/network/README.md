# `core/network/`

Carpeta reservada. Gastegi es hoy una app **100 % local**: no hay API, ni
cliente HTTP, ni comprobación de conectividad, y por eso no hay ningún `.dart`
aquí. Un `api_client.dart` vacío sería código muerto y el analizador lo trataría
como tal.

Cuando llegue la sincronización en la nube, este es su sitio: cliente HTTP,
interceptores, cabeceras, refresco de token y `network_info.dart`.

El esquema de la base de datos ya está preparado para ese momento (ver
`core/storage/app_database.dart`):

- claves primarias UUID, para que dos dispositivos no generen el mismo `id`;
- `created_at` / `updated_at` / `deleted_at` en todas las tablas;
- borrados lógicos con *tombstone*, para que un borrado hecho en un teléfono no
  sea invisible para el servidor;
- índices `UNIQUE` parciales (`WHERE deleted_at IS NULL`), para poder reutilizar
  un nombre ya borrado;
- transferencias como filas inmutables en vez de mutaciones del saldo, porque un
  contador mutado no es fusionable;
- tabla `sync_state` con un `device_id` estable (ver `core/storage/local_storage.dart`).
