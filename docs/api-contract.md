# SolarO — Contrato de API

**Versión vigente del contrato:** 2.1.0
**Backend:** Python + Flask
**Base de datos:** PostgreSQL
**Consumidores:** aplicación Flutter y aplicación web

Este documento reúne lo que es común a todos los módulos de la API: convenciones, tipos de token, formato de errores y control de versiones. El detalle de cada endpoint está en el documento de su módulo.

## Módulos

| Módulo | Prefijo | Documento | Introducido en |
|---|---|---|---|
| Autenticación | `/auth` | [auth.md](auth.md) | 1.0.0 |
| Usuarios | `/users` | [users.md](users.md) | 2.0.0 |
| Electrodomésticos | `/appliances` | [appliances.md](appliances.md) | 2.1.0 |

## 1. Información general

- **Formato de intercambio:** JSON.
- **Protocolo:** HTTP (HTTPS en producción).
- **Autenticación:** JWT mediante el encabezado `Authorization: Bearer <token>`.
- **Codificación:** UTF-8.

### URL base

| Entorno | URL base |
|---|---|
| Desarrollo local | `http://127.0.0.1:5000` |
| Emulador Android | `http://10.0.2.2:5000` |
| Producción | Sin definir |

## 2. Convenciones

- Las peticiones y respuestas con contenido JSON utilizan `Content-Type: application/json`.
- Todos los campos listados en una petición son obligatorios. **No se aceptan campos adicionales**: si el cuerpo contiene campos de más o de menos, la respuesta es `422`.
- Todos los campos de texto deben ser cadenas (`String`); cualquier otro tipo produce `422`.
- Los códigos HTTP indican si la operación tuvo éxito o qué clase de error ocurrió:
  - `400`: el cuerpo no es un objeto JSON válido.
  - `401`: autenticación ausente, inválida o vencida, o credenciales incorrectas.
  - `403`: el token es válido, pero no es del tipo que exige la ruta.
  - `404`: el recurso asociado al token ya no existe.
  - `409`: el recurso entra en conflicto con uno existente.
  - `422`: el cuerpo es un objeto JSON, pero sus datos son incompletos o inválidos.
  - `500`: error inesperado del servidor, incluida la pérdida de conexión con la base de datos.
- Las contraseñas se envían únicamente al backend, por HTTPS en producción. Nunca se devuelve la contraseña original.
- El frontend no debe enviar el ID del usuario para decidir a qué cuenta pertenecen sus datos: el backend lo obtiene de la identidad autenticada.

## 3. Tokens y sesión

### Tipos de token

La API emite tres tipos de token. Cada ruta protegida acepta únicamente el tipo que le corresponde y rechaza los demás.

| Token | Obtención | Duración | Uso |
|---|---|---|---|
| Acceso (sesión) | `POST /auth/login`, `POST /auth/refresh` | 15 minutos | Rutas protegidas (`/users/...`, `/appliances/...`). |
| Refresco | `POST /auth/login`, `POST /auth/refresh`, `PUT /users/me/password` | 7 días desde su emisión | Únicamente `POST /auth/refresh`. |
| Recuperación | Enlace enviado por correo (`POST /auth/forgot-password`) | 15 minutos, de un solo uso | Únicamente `POST /auth/reset-password`. |

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

Cuando el error identifica un campo concreto, se incluye `field`:

```json
{
  "message": "El correo electrónico ya está registrado.",
  "field": "email"
}
```

Los errores de autenticación del token (ausente, inválido o vencido) también siguen este formato y devuelven siempre `401`.

## 5. Control de versiones

El contrato usa versionado semántico (`MAYOR.MENOR.PARCHE`):

| Componente | Cuándo aumenta |
|---|---|
| MAYOR | Un cambio incompatible exige que los consumidores se adapten (retirar o renombrar un endpoint o campo, cambiar un código de respuesta, cambiar el tipo de un campo). |
| MENOR | Se añade funcionalidad compatible (endpoint nuevo, campo opcional nuevo en una respuesta, módulo nuevo). |
| PARCHE | Se corrige la documentación sin cambiar el comportamiento. |

Reglas de mantenimiento:

- La versión del contrato es única y se indica al inicio de este documento. Cada módulo indica desde qué versión existe cada endpoint (`Desde`).
- Todo cambio del contrato se registra en el historial de esta sección en el mismo cambio que lo introduce.
- Cada versión publicada se marca con una etiqueta (`tag`) en GitHub con el mismo número, por ejemplo `v2.1.0`.
- Todo cambio incompatible aumenta la versión MAYOR, aunque todavía no exista un entorno de producción. Una versión que reúne cambios incompatibles y compatibles aumenta MAYOR.
- Un endpoint retirado se conserva en la sección «Endpoints retirados» de su módulo, con la versión en que se retiró y su reemplazo.

## 6. Historial de versiones

| Versión | Módulos afectados | Resumen | Compatibilidad |
|---|---|---|---|
| 2.1.0 | appliances | Nuevo módulo de electrodomésticos | Compatible |
| 2.0.0 | auth, users | Nuevo módulo de usuarios; `GET /auth/me` pasa a `GET /users/me`; renovación de sesión con refresco deslizante; recuperación de contraseña de un solo uso | Incompatible |
| 1.0.0 | auth | Contrato inicial de autenticación | — |

### 2.1.0

**Añadido**

- Módulo de electrodomésticos ([appliances.md](appliances.md)): `GET /appliances`, `POST /appliances`, `GET /appliances/info`, `GET /appliances/{id}`, `PUT /appliances/{id}` y `DELETE /appliances/{id}`. Todos requieren un token de acceso.

### 2.0.0

**Añadido**

- Módulo de usuarios ([users.md](users.md)): `GET /users/me`, `PUT /users/me` y `PUT /users/me/password`.
- `POST /auth/refresh`: entrega un nuevo token de acceso y un nuevo token de refresco (sesión deslizante de 7 días).
- Los tokens de acceso llevan el propósito `session`, y las rutas protegidas rechazan con `403` cualquier otro tipo de token.
- Aviso por correo, con fecha, dispositivo e IP, tras restablecer o cambiar la contraseña.

**Cambiado**

- `POST /auth/login`: la respuesta incluye además `refresh_token`. Compatible.
- `POST /auth/reset-password`: el token de recuperación es de un solo uso; un token ya utilizado responde `401`. Compatible.
- Se documentan las respuestas `500` por pérdida de conexión con la base de datos.

**Retirado**

- `GET /auth/me`, reemplazado por `GET /users/me`. **Incompatible.**

### 1.0.0

**Añadido**

- Módulo de autenticación ([auth.md](auth.md)): `POST /auth/register`, `POST /auth/login`, `POST /auth/forgot-password`, `POST /auth/reset-password` y `GET /auth/me`.
- Token de acceso JWT y token de recuperación de contraseña con propósito `password_reset`.