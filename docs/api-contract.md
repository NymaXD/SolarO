# SolarO — Contrato de API

**Versión:** 1.1
**Backend:** Python + Flask
**Base de datos:** PostgreSQL
**Consumidor:** Aplicación Flutter

## 1. Información general

- **Formato de intercambio:** JSON.
- **Protocolo:** HTTP (HTTPS en producción).
- **Prefijo de autenticación:** `/auth`.
- **Autenticación:** JWT mediante el encabezado `Authorization: Bearer <token>`.
- **Codificación:** UTF-8.

### URL base

| Entorno | URL base |
|---|---|
| Desarrollo local | `http://127.0.0.1:5000` |
| Emulador Android | `http://10.0.2.2:5000` |
| Producción | `https://solaro-jboy.onrender.com` |

## 2. Convenciones

- Las peticiones y respuestas con contenido JSON utilizan `Content-Type: application/json`.
- Todos los campos listados en una petición son obligatorios. **No se aceptan campos adicionales**: si el cuerpo contiene campos de más o de menos, la respuesta es `422`.
- Todos los campos de texto deben ser cadenas (`String`); cualquier otro tipo produce `422`.
- Los códigos HTTP indican si la operación tuvo éxito o qué clase de error ocurrió:
  - `400`: el cuerpo no es un objeto JSON válido.
  - `422`: el cuerpo es un objeto JSON, pero sus datos son incompletos o inválidos.
- Las contraseñas se envían únicamente al backend, por HTTPS en producción. Nunca se devuelve la contraseña original.
- Las rutas protegidas requieren un token de acceso válido.
- El frontend no debe enviar el ID del usuario para decidir a qué cuenta pertenecen sus datos: el backend lo obtiene de la identidad autenticada.

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
- `500 Internal Server Error`: error inesperado al crear el usuario.

**Ejemplo de error `409`**

```json
{
  "message": "El correo electrónico ya está registrado.",
  "field": "email"
}
```

**Política de seguridad de la contraseña**

Toda contraseña ingresada al registrar un usuario o al restablecerla en caso de olvido debe cumplir:

- Mínimo 8 caracteres de longitud.
- Al menos una letra mayúscula.
- Al menos una letra minúscula.
- Al menos un número.

Si no se cumple, la respuesta es `422` con el detalle en `notes` (ver sección 4).

### 3.2 Iniciar sesión

**`POST /auth/login`**

Valida las credenciales y entrega el token de acceso.

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
  "access_token": "<JWT>",
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

El frontend debe conservar el `access_token` de forma segura y utilizarlo en las peticiones que requieren autenticación.

### 3.3 Solicitar recuperación de contraseña

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

### 3.4 Restablecer contraseña

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

**Errores esperados**

- `400 Bad Request`: el cuerpo no es un objeto JSON válido.
- `401 Unauthorized`: token ausente, inválido o vencido.
- `403 Forbidden`: token válido, pero no es un token de recuperación (por ejemplo, un token de sesión).
- `404 Not Found`: el usuario asociado al token ya no existe.
- `422 Unprocessable Entity`: falta el campo `contrasena`, hay campos adicionales, el valor no es una cadena, está vacío o no cumple la política de seguridad.
- `500 Internal Server Error`: error inesperado al actualizar la contraseña.

El frontend debe obtener el token de recuperación del enlace enviado por correo y enviar únicamente el token, no la URL completa, en el encabezado.

**Nota de seguridad:** el token de recuperación tiene una finalidad distinta (`purpose = password_reset`) a la del token de acceso. Las rutas protegidas habituales rechazan los tokens de recuperación con `403`, y esta ruta rechaza los tokens de sesión con `403`.

### 3.5 Obtener perfil

**`GET /auth/me`**

Devuelve los datos del usuario autenticado.

**Encabezado requerido**

```http
Authorization: Bearer <ACCESS_TOKEN>
```

**Respuesta exitosa — `200 OK`**

```json
{
  "id_usuario": 12,
  "nombre": "Ana Pérez",
  "email": "ana@example.com"
}
```

**Errores esperados**

- `401 Unauthorized`: token ausente, inválido o vencido.
- `403 Forbidden`: el token es de recuperación de contraseña, no de sesión.
- `404 Not Found`: el usuario asociado al token ya no existe.

## 4. Formato de errores

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