# SolarO — Contrato de API: módulo Auth

**Prefijo:** `/auth`
**Introducido en:** 1.0.0
**Versión vigente del contrato:** 2.1.0

Las convenciones generales, los tipos de token y el formato de errores están en [api-contract.md](api-contract.md). Cada endpoint indica la versión desde la que existe (`Desde`) y, cuando cambió, en qué versión.

## Endpoints

| Método | Ruta | Descripción | Desde |
|---|---|---|---|
| POST | `/auth/register` | Registrar usuario | 1.0.0 |
| POST | `/auth/login` | Iniciar sesión | 1.0.0 |
| POST | `/auth/refresh` | Renovar sesión | 2.0.0 |
| POST | `/auth/forgot-password` | Solicitar recuperación de contraseña | 1.0.0 |
| POST | `/auth/reset-password` | Restablecer contraseña | 1.0.0 |

## 1. Registrar usuario

**`POST /auth/register`** · Desde 1.0.0

Registra una nueva cuenta.

**Petición**

```json
{
  "nombre": "Ana Pérez",
  "email": "ana@example.com",
  "contrasena": "ClaveSegura123"
}
```

| Campo | Tipo | Obligatorio | Reglas |
|---|---|---|---|
| `nombre` | String | Sí | No puede estar vacío, no puede ser solo numérico y debe tener al menos 3 caracteres. |
| `email` | String | Sí | Debe tener formato de correo válido. Se normaliza (se eliminan espacios laterales y se convierte a minúsculas). |
| `contrasena` | String | Sí | Debe cumplir la política de seguridad (ver abajo). |

**Respuesta exitosa — `201 Created`**

```json
{
  "message": "Usuario creado correctamente."
}
```

**Errores esperados**

- `400 Bad Request`: el cuerpo no es un objeto JSON válido.
- `409 Conflict`: el correo ya está registrado. La respuesta incluye `"field": "email"`.
- `422 Unprocessable Entity`: faltan campos o hay campos adicionales, algún valor no es una cadena, el nombre es vacío, numérico o de menos de 3 caracteres, el email tiene formato inválido o la contraseña no cumple la política de seguridad.
- `500 Internal Server Error`: error de conexión con la base de datos o error inesperado al crear el usuario.

### Política de seguridad de la contraseña

Toda contraseña ingresada al registrar un usuario, al restablecerla en caso de olvido o al cambiarla desde la cuenta ([users.md](users.md)) debe cumplir:

- Mínimo 8 caracteres de longitud.
- Al menos una letra mayúscula.
- Al menos una letra minúscula.
- Al menos un número.

Si no se cumple, la respuesta es `422` con el detalle en `notes`:

```json
{
  "message": "La contraseña no cumple los requisitos.",
  "notes": [
    "Debe tener al menos 8 caracteres."
  ]
}
```

## 2. Iniciar sesión

**`POST /auth/login`** · Desde 1.0.0 · Modificado en 2.0.0 (añade `refresh_token`)

Valida las credenciales y entrega los tokens de acceso y de refresco.

**Petición**

```json
{
  "email": "ana@example.com",
  "contrasena": "ClaveSegura123"
}
```

| Campo | Tipo | Obligatorio |
|---|---|---|
| `email` | String | Sí |
| `contrasena` | String | Sí |

El email se normaliza (sin espacios laterales y en minúsculas) antes de buscar la cuenta.

**Respuesta exitosa — `200 OK`**

```json
{
  "message": "Inicio de sesión exitoso.",
  "access_token": "<JWT_ACCESO>",
  "refresh_token": "<JWT_REFRESCO>",
  "user": {
    "id_usuario": 12,
    "nombre": "Ana Pérez",
    "email": "ana@example.com"
  }
}
```

**Errores esperados**

- `400 Bad Request`: el cuerpo no es un objeto JSON válido.
- `401 Unauthorized`: correo o contraseña incorrectos. El mensaje es el mismo en ambos casos para no revelar qué correos están registrados.
- `422 Unprocessable Entity`: faltan campos o hay campos adicionales, algún valor no es una cadena, o `email`/`contrasena` están vacíos.
- `500 Internal Server Error`: error de conexión con la base de datos.

## 3. Renovar sesión

**`POST /auth/refresh`** · Desde 2.0.0

Entrega un nuevo token de acceso y un nuevo token de refresco a partir de un token de refresco vigente. No lleva cuerpo.

**Encabezado requerido**

```http
Authorization: Bearer <TOKEN_DE_REFRESCO>
```

**Respuesta exitosa — `200 OK`**

```json
{
  "access_token": "<JWT_ACCESO>",
  "refresh_token": "<JWT_REFRESCO>"
}
```

El cliente debe reemplazar el token de refresco guardado por el recibido.

**Errores esperados**

- `401 Unauthorized`: token ausente, inválido o vencido; el token no es de refresco; el usuario ya no existe, o la contraseña cambió después de emitirse el token.

## 4. Solicitar recuperación de contraseña

**`POST /auth/forgot-password`** · Desde 1.0.0

Solicita el envío de un enlace para recuperar la contraseña.

**Petición**

```json
{
  "email": "ana@example.com"
}
```

| Campo | Tipo | Obligatorio |
|---|---|---|
| `email` | String | Sí |

**Respuesta — `200 OK`**

```json
{
  "message": "Si el correo está registrado, recibirás instrucciones para recuperar tu contraseña."
}
```

La respuesta es la misma tanto si el correo existe como si no, y también si el envío del correo falla, para no revelar qué cuentas están registradas.

**Errores esperados**

- `400 Bad Request`: el cuerpo no es un objeto JSON válido.
- `422 Unprocessable Entity`: falta el campo `email`, hay campos adicionales, el valor no es una cadena o el email está vacío.
- `500 Internal Server Error`: error de conexión con la base de datos.

## 5. Restablecer contraseña

**`POST /auth/reset-password`** · Desde 1.0.0 · Modificado en 2.0.0 (token de un solo uso y aviso por correo)

Establece una nueva contraseña utilizando un token de recuperación vigente.

**Encabezados requeridos**

```http
Authorization: Bearer <TOKEN_DE_RECUPERACION>
Content-Type: application/json
```

**Petición**

```json
{
  "contrasena": "NuevaClave123"
}
```

| Campo | Tipo | Obligatorio | Reglas |
|---|---|---|---|
| `contrasena` | String | Sí | No puede estar vacía y debe cumplir la política de seguridad. |

**Respuesta exitosa — `200 OK`**

```json
{
  "message": "Contraseña actualizada correctamente. Ahora puede iniciar sesión."
}
```

Tras el cambio, el usuario recibe un correo de aviso con la fecha, el dispositivo y la dirección IP desde donde se realizó.

**Errores esperados**

- `400 Bad Request`: el cuerpo no es un objeto JSON válido.
- `401 Unauthorized`: token ausente, inválido, vencido o ya utilizado.
- `403 Forbidden`: token válido, pero no es un token de recuperación.
- `404 Not Found`: el usuario asociado al token ya no existe.
- `422 Unprocessable Entity`: falta el campo `contrasena`, hay campos adicionales, el valor no es una cadena, está vacío o no cumple la política de seguridad.
- `500 Internal Server Error`: error inesperado al actualizar la contraseña.

El frontend debe obtener el token de recuperación del enlace enviado por correo y enviar únicamente el token, no la URL completa, en el encabezado.

## Endpoints retirados

| Método | Ruta | Retirado en | Reemplazo |
|---|---|---|---|
| GET | `/auth/me` | 2.0.0 | `GET /users/me` ([users.md](users.md)) |