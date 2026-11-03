# Feedback — Comentarios de usuarios

Endpoint para que el usuario autenticado envíe un comentario, que se entrega por correo al equipo de SolarO. El comentario no se almacena en la base de datos.

**Prefijo:** `/feedback`
**Autenticación:** requerida (`Authorization: Bearer <access_token>`). El nombre y el email del usuario nunca se envían en el cuerpo: el servidor los toma de la sesión.

---

## POST /feedback

Envía un comentario por correo.

### Cuerpo

```json
{ "mensaje": "Me gustaría ver más lecciones sobre paneles solares.", "compartir_datos": true }
```

| Campo             | Tipo      | Reglas                                                                 |
|-------------------|-----------|------------------------------------------------------------------------|
| `mensaje`         | cadena    | Requerido. No vacío tras recortar espacios; máximo 1000 caracteres.    |
| `compartir_datos` | booleano  | Opcional (por defecto `false`). Debe ser un booleano estricto.         |

### Tratamiento de los datos del usuario

- Con `compartir_datos: true`, el correo incluye el **nombre** y el **email** del usuario autenticado, y el email se usa como dirección de respuesta.
- Con `false` u omitido, el correo se envía como anónimo y no incluye ningún dato del usuario.
- No se recopila ningún otro dato.

### Límite de envíos

Máximo **3 comentarios por usuario por hora**. Los envíos rechazados por validación o fallidos por el proveedor de correo no cuentan.

### Respuestas

| Código | Cuándo                                                       |
|--------|--------------------------------------------------------------|
| 200    | Comentario enviado.                                          |
| 401    | Sesión ausente o inválida.                                   |
| 422    | Cuerpo ausente, `mensaje` inválido o `compartir_datos` no booleano. |
| 429    | Se superó el límite de envíos.                               |
| 502    | El proveedor de correo no pudo entregar el comentario.       |

**200**

```json
{ "enviado": true }
```

**422 / 429 / 502**

```json
{ "message": "'mensaje' no puede superar 1000 caracteres" }
```

Ante un 502 el comentario no se guarda en el servidor: el cliente debe conservar el texto para permitir al usuario reintentar.