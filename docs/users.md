# SolarO — Contrato de API: módulo Users

**Prefijo:** `/users`
**Introducido en:** 2.0.0
**Versión vigente del contrato:** 2.1.0

Las convenciones generales, los tipos de token y el formato de errores están en [api-contract.md](api-contract.md). Este módulo reemplazó a `GET /auth/me`, retirado en 2.0.0 ([auth.md](auth.md)).

Todos los endpoints requieren un token de **acceso**:

```http
Authorization: Bearer <ACCESS_TOKEN>
```

Un token de refresco o de recuperación se rechaza con `403`.

## Endpoints

| Método | Ruta | Descripción | Desde |
|---|---|---|---|
| GET | `/users/me` | Obtener perfil | 2.0.0 |
| PUT | `/users/me` | Actualizar nombre y correo | 2.0.0 |
| PUT | `/users/me/password` | Cambiar contraseña | 2.0.0 |

## 1. Obtener perfil

**`GET /users/me`** · Desde 2.0.0 (antes, `GET /auth/me`)

Devuelve los datos del usuario autenticado.

**Respuesta exitosa — `200 OK`**

```json
{
  "id_usuario": 12,
  "nombre": "Ana Pérez",
  "email": "ana@example.com"
}
```

**Errores esperados**

- `401 Unauthorized`: token ausente, inválido o vencido, o el usuario asociado al token ya no existe.
- `403 Forbidden`: el token no es de acceso.

## 2. Actualizar datos del usuario

**`PUT /users/me`** · Desde 2.0.0

Actualiza el nombre y el correo del usuario autenticado.

**Petición**

```json
{
  "nombre": "Ana María Pérez",
  "email": "ana.nueva@example.com"
}
```

| Campo | Tipo | Obligatorio | Reglas |
|---|---|---|---|
| `nombre` | String | Sí | Mismas reglas que en el registro: no vacío, no solo numérico y al menos 3 caracteres. |
| `email` | String | Sí | Formato válido; se normaliza. No puede pertenecer a otro usuario. Puede conservarse el actual. |

**Respuesta exitosa — `204 No Content`** (sin cuerpo).

**Errores esperados**

- `400 Bad Request`: el cuerpo no es un objeto JSON válido.
- `401 Unauthorized`: token ausente, inválido o vencido, o el usuario ya no existe.
- `403 Forbidden`: el token no es de acceso.
- `409 Conflict`: el correo pertenece a otro usuario. Incluye `"field": "email"`.
- `422 Unprocessable Entity`: faltan campos o hay campos adicionales, algún valor no es una cadena, el nombre es inválido o el email tiene formato inválido.
- `500 Internal Server Error`: error de conexión con la base de datos o error inesperado.

## 3. Cambiar contraseña

**`PUT /users/me/password`** · Desde 2.0.0

Cambia la contraseña del usuario autenticado verificando la contraseña actual.

**Petición**

```json
{
  "contrasena_antigua": "ClaveSegura123",
  "contrasena_nueva": "NuevaClave456"
}
```

| Campo | Tipo | Obligatorio | Reglas |
|---|---|---|---|
| `contrasena_antigua` | String | Sí | Debe coincidir con la contraseña actual. |
| `contrasena_nueva` | String | Sí | Debe cumplir la política de seguridad ([auth.md](auth.md#política-de-seguridad-de-la-contraseña)). |

**Respuesta exitosa — `200 OK`**

```json
{
  "message": "Contraseña actualizada correctamente.",
  "refresh_token": "<JWT_REFRESCO>"
}
```

Todos los tokens de refresco anteriores quedan invalidados. El cliente debe reemplazar el token de refresco guardado por el recibido para conservar la sesión en ese dispositivo. El usuario recibe además un correo de aviso con la fecha, el dispositivo y la dirección IP del cambio.

**Errores esperados**

- `400 Bad Request`: el cuerpo no es un objeto JSON válido.
- `401 Unauthorized`: token ausente, inválido o vencido, o el usuario ya no existe.
- `403 Forbidden`: el token no es de acceso.
- `422 Unprocessable Entity`: faltan campos o hay campos adicionales, algún valor no es una cadena o está vacío, la contraseña nueva no cumple la política, o la contraseña actual es incorrecta (`"field": "contrasena_antigua"`).
- `500 Internal Server Error`: error inesperado.