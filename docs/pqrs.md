# PQRS — Peticiones, quejas, reclamos y sugerencias

Endpoint para que el usuario autenticado radique una PQRS. Cada solicitud se registra en la base de datos, se notifica por correo al equipo de SolarO y se envía al usuario un correo de confirmación con su número de radicado. La respuesta a la solicitud se da de forma personal por correo electrónico.

**Prefijo:** `/pqrs`
**Autenticación:** requerida (`Authorization: Bearer <access_token>`).

---

## POST /pqrs

Radica una PQRS.

### Cuerpo

```json
{
  "tipo": "sugerencia",
  "numero_radicado": "PQRS-20261103-0042",
  "nombre": "Ana Pérez",
  "email": "ana@example.com",
  "asunto": "Más lecciones de paneles",
  "descripcion": "Me gustaría ver más lecciones sobre instalación de paneles solares.",
  "calificacion": 4
}
```

| Campo             | Tipo    | Reglas                                                                                   |
|-------------------|---------|------------------------------------------------------------------------------------------|
| `tipo`            | cadena  | Requerido. `peticion`, `queja`, `reclamo` o `sugerencia`.                                |
| `numero_radicado` | cadena  | Requerido. Generado por el cliente. Máx. 50 caracteres; solo letras, números, `-` y `_`. Debe ser único. |
| `nombre`          | cadena  | Requerido. Máx. 100 caracteres, sin saltos de línea.                                     |
| `email`           | cadena  | Requerido. Formato de correo válido; máx. 254 caracteres. Es el correo al que se responde. |
| `asunto`          | cadena  | Requerido. Máx. 30 caracteres, sin saltos de línea.                                      |
| `descripcion`     | cadena  | Requerido. Máx. 1000 caracteres.                                                         |
| `calificacion`    | entero  | Opcional (puede omitirse o ser `null`). De 1 a 5.                                        |

Los textos se recortan de espacios al inicio y al final antes de validar la longitud.

### Datos almacenados

En la base de datos se guardan únicamente: número de radicado, ID del usuario autenticado, tipo, asunto, descripción y fecha y hora de registro. El nombre, el email y la calificación solo se incluyen en el correo enviado al equipo de SolarO.

### Correos

- **Al equipo de SolarO:** notificación con todos los datos de la solicitud; la dirección de respuesta es el email del usuario.
- **Al usuario:** confirmación de radicación con su número de radicado, enviada al `email` indicado.

### Límite de solicitudes

Máximo **3 PQRS por usuario por hora**. Las solicitudes rechazadas por validación o por fallo del correo no cuentan.

### Respuestas

| Código | Cuándo                                                                   |
|--------|--------------------------------------------------------------------------|
| 201    | PQRS radicada y notificada al equipo.                                    |
| 401    | Sesión ausente o inválida.                                               |
| 409    | El `numero_radicado` ya existe.                                          |
| 422    | Cuerpo ausente o algún campo inválido.                                   |
| 429    | Se superó el límite de solicitudes.                                      |
| 502    | No se pudo notificar al equipo; **no se guardó nada** y puede reintentarse. |

**201**

```json
{ "radicado": "PQRS-20261103-0042", "confirmacion_enviada": true }
```

`confirmacion_enviada` es `false` si la solicitud quedó radicada pero el correo de confirmación al usuario no pudo enviarse. En ese caso la PQRS **sí está registrada** y no debe reenviarse.

**409 / 422 / 429 / 502**

```json
{ "message": "El número de radicado ya existe" }
```

---

## GET /pqrs

Devuelve las PQRS radicadas por el usuario autenticado, de la más reciente a la más antigua. Solo se devuelven las del propio usuario. No lleva parámetros ni cuerpo y no tiene paginación.

### Respuestas

| Código | Cuándo                                              |
|--------|-----------------------------------------------------|
| 200    | Lista de PQRS (vacía si el usuario no ha radicado). |
| 401    | Sesión ausente o inválida.                          |

**200**

```json
{
  "pqrs": [
    {
      "numero_radicado": "PQRS-20261103-0042",
      "tipo": "sugerencia",
      "asunto": "Más lecciones de paneles",
      "fecha": "2026-11-03T21:10:00+00:00"
    }
  ]
}
```

| Campo             | Descripción                                                              |
|-------------------|--------------------------------------------------------------------------|
| `numero_radicado` | Número de radicado de la solicitud.                                      |
| `tipo`            | `peticion`, `queja`, `reclamo` o `sugerencia`.                           |
| `asunto`          | Asunto indicado por el usuario.                                          |
| `fecha`           | Fecha y hora de radicación en ISO 8601, en UTC.                          |