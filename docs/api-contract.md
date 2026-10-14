# SolarO — Contrato de API

**Versión:** 1.2
**Backend:** Python + Flask
**Base de datos:** PostgreSQL
**Consumidor:** Aplicación Flutter y aplicación web

## 1. Información general

- **Formato de intercambio:** JSON.
- **Protocolo:** HTTP (HTTPS en producción).
- **Prefijos:** `/auth` (autenticación) y `/users` (gestión del usuario autenticado).
- **Autenticación:** JWT mediante el encabezado `Authorization: Bearer <token>`.
- **Codificación:** UTF-8.

### URL base

| Entorno | URL base |
|---|---|
| Desarrollo local | `http://127.0.0.1:5000` |
| Emulador Android | `http://10.0.2.2:5000` |
| Producción | https://solaro-jboy.onrender.com |

## 2. Convenciones

- Las peticiones y respuestas con contenido JSON utilizan `Content-Type: application/json`.
- Todos los campos listados en una petición son obligatorios. **No se aceptan campos adicionales**: si el cuerpo contiene campos de más o de menos, la respuesta es `422`.
- Todos los campos de texto deben ser cadenas (`String`); cualquier otro tipo produce `422`.
- Los códigos HTTP indican si la operación tuvo éxito o qué clase de error ocurrió:
  - `400`: el cuerpo no es un objeto JSON válido.
  - `422`: el cuerpo es un objeto JSON, pero sus datos son incompletos o inválidos.
  - `500`: error inesperado del servidor, incluida la pérdida de conexión con la base de datos.
- Las contraseñas se envían únicamente al backend, por HTTPS en producción. Nunca se devuelve la contraseña original.
- El frontend no debe enviar el ID del usuario para decidir a qué cuenta pertenecen sus datos: el backend lo obtiene de la identidad autenticada.

### Tipos de token

La API emite tres tipos de token. Cada ruta protegida acepta únicamente el tipo que le corresponde y rechaza los demás.

| Token | Obtención | Duración | Uso |
|---|---|---|---|
| Acceso (sesión) | `POST /auth/login`, `POST /auth/refresh` | 15 minutos | Rutas protegidas (`/users/...`). |
| Refresco | `POST /auth/login`, `POST /auth/refresh`, `PUT /users/me/password` | 7 días desde su emisión | Únicamente `POST /auth/refresh`. |
| Recuperación | Enlace enviado por correo (`/auth/forgot-password`) | 15 minutos, de un solo uso | Únicamente `POST /auth/reset-password`. |

- Un token de refresco o de recuperación no sirve como token de acceso, ni viceversa.
- **Sesión deslizante:** cada renovación entrega un token de refresco nuevo con otros 7 días de vida. Una sesión se mantiene mientras el usuario la use al menos una vez cada 7 días; tras 7 días de inactividad, debe iniciar sesión de nuevo.
- El token de recuperación deja de ser válido en cuanto se restablece la contraseña.
- Al cambiar la contraseña (por recuperación o desde la cuenta), todos los tokens de refresco emitidos antes quedan invalidados. En el cambio desde la cuenta, el dispositivo que lo realiza recibe un token de refresco nuevo y conserva su sesión; los demás dispositivos deberán iniciar sesión de nuevo.
- Los tokens de acceso ya emitidos siguen siendo válidos hasta su vencimiento (máximo 15 minutos), incluso después de un cambio de contraseña.

### Mantener la sesión

1. El cliente guarda ambos tokens de forma segura (en móvil, almacenamiento seguro del sistema).
2. Envía el token de acceso en cada petición protegida.
3. Si recibe `401`, solicita un nuevo token de acceso con `POST /auth/refresh`, **reemplaza el token de refresco guardado por el nuevo** y repite la petición una sola vez.
4. Si el refresco también responde `401`, la sesión terminó y el usuario debe iniciar sesión de nuevo.
5. Para cerrar sesión, el cliente elimina ambos tokens.

## 3. Endpoints de autenticación

### 3.1 Registrar usuario

**`POST /auth/register`**

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

**Ejemplo de error `409`**

```json
{
  "message": "El correo electrónico ya está registrado.",
  "field": "email"
}
```

**Política de seguridad de la contraseña**

Toda contraseña ingresada al registrar un usuario, al restablecerla en caso de olvido o al cambiarla desde la cuenta debe cumplir:

- Mínimo 8 caracteres de longitud.
- Al menos una letra mayúscula.
- Al menos una letra minúscula.
- Al menos un número.

Si no se cumple, la respuesta es `422` con el detalle en `notes` (ver sección 5).

### 3.2 Iniciar sesión

**`POST /auth/login`**

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

### 3.3 Renovar sesión

**`POST /auth/refresh`**

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

### 3.4 Solicitar recuperación de contraseña

**`POST /auth/forgot-password`**

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

### 3.5 Restablecer contraseña

**`POST /auth/reset-password`**

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
| `contrasena` | String | Sí | No puede estar vacía y debe cumplir la política de seguridad (sección 3.1). |

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

## 4. Endpoints de usuario

Todos requieren un token de **acceso** (`Authorization: Bearer <ACCESS_TOKEN>`). Un token de refresco o de recuperación se rechaza con `403`.

### 4.1 Obtener perfil

**`GET /users/me`**

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

### 4.2 Actualizar datos del usuario

**`PUT /users/me`**

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
| `nombre` | String | Sí | Mismas reglas que en el registro. |
| `email` | String | Sí | Formato válido; se normaliza. No puede pertenecer a otro usuario. Puede conservarse el actual. |

**Respuesta exitosa — `204 No Content`** (sin cuerpo).

**Errores esperados**

- `400 Bad Request`: el cuerpo no es un objeto JSON válido.
- `401 Unauthorized`: token ausente, inválido o vencido, o el usuario ya no existe.
- `403 Forbidden`: el token no es de acceso.
- `409 Conflict`: el correo pertenece a otro usuario. Incluye `"field": "email"`.
- `422 Unprocessable Entity`: faltan campos o hay campos adicionales, algún valor no es una cadena, el nombre es inválido o el email tiene formato inválido.
- `500 Internal Server Error`: error de conexión con la base de datos o error inesperado.

### 4.3 Cambiar contraseña

**`PUT /users/me/password`**

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
| `contrasena_nueva` | String | Sí | Debe cumplir la política de seguridad (sección 3.1). |

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

## 5. Formato de errores

Todas las respuestas de error usan la misma estructura:

```json
{
  "message": "Descripción del error."
}
```

Si hay detalles adicionales de validación, se incluyen en el campo `notes`:

```json
{
  "message": "La contraseña no cumple los requisitos.",
  "notes": [
    "Debe tener al menos 8 caracteres."
  ]
}
```

Los errores de autenticación del token (ausente, inválido o vencido) también siguen este formato y devuelven siempre `401`.
