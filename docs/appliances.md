# SolarO — Contrato de API: módulo Appliances

**Prefijo:** `/appliances`
**Introducido en:** 2.1.0
**Versión vigente del contrato:** 2.1.0

Gestión de los electrodomésticos del usuario autenticado y consulta del catálogo de tipos disponibles. El consumo mensual **no se almacena**: se calcula al responder.

Las convenciones generales, los tipos de token y el formato de errores están en [api-contract.md](api-contract.md).

## Convenciones del módulo

- **Autenticación:** todos los endpoints exigen un token de **acceso** (`Authorization: Bearer <ACCESS_TOKEN>`), igual que el resto de rutas protegidas. Los errores de autenticación se describen más abajo.
- **Formato:** peticiones y respuestas en `application/json`.
- **Errores:** cuerpo `{"message": "<texto>"}`, según [api-contract.md](api-contract.md#4-formato-de-errores).
- **Propiedad:** cada usuario solo ve y modifica sus electrodomésticos. Pedir un `id` que no existe o que pertenece a otro usuario produce el mismo `404`.

## Endpoints

| Método | Ruta | Descripción | Éxito | Desde |
|--------|------|-------------|-------|-------|
| GET | `/appliances/info` | Catálogo de tipos y su potencia | 200 | 2.1.0 |
| GET | `/appliances` | Lista los electrodomésticos del usuario | 200 | 2.1.0 |
| GET | `/appliances/{id}` | Obtiene uno (para precargar la edición) | 200 | 2.1.0 |
| POST | `/appliances` | Crea un electrodoméstico | 201 | 2.1.0 |
| PUT | `/appliances/{id}` | Reemplaza todos los datos editables | 204 | 2.1.0 |
| DELETE | `/appliances/{id}` | Elimina un electrodoméstico | 204 | 2.1.0 |

`{id}` es un entero (`id_electrodomestico`).

## Errores de autenticación (todos los endpoints)

| Código | Causa |
|--------|-------|
| 401 | Token ausente, inválido o vencido, o el usuario asociado al token ya no existe. |
| 403 | El token es válido, pero no es un token de acceso. |

Se suman a los errores propios de cada endpoint.

## Objeto Electrodoméstico

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id_electrodomestico` | entero | Identificador |
| `nombre` | string | Nombre dado por el usuario |
| `tipo` | string | Nombre de un tipo del catálogo |
| `potencia_w` | entero | Potencia en W tomada del catálogo |
| `consumo_mensual` | número | Consumo estimado en kWh/mes, redondeado a 2 decimales |
| `horas_dia` | número | Horas de uso por día |
| `dias_semana` | entero | Días de uso por semana |
| `cantidad` | entero | Unidades |

**Cálculo:** `consumo_mensual = (potencia_w / 1000) × horas_dia × dias_semana × 4.33 × cantidad`

## Reglas de validación (POST y PUT)

El cuerpo debe ser un objeto JSON con **exactamente** estos cinco campos; faltar uno o enviar uno adicional es un error `422`.

| Campo | Regla |
|-------|-------|
| `nombre` | string, no vacío tras eliminar espacios en los extremos (se guarda sin ellos) |
| `tipo` | string no vacío que coincida exactamente (sensible a mayúsculas) con un nombre de `GET /appliances/info` |
| `horas_dia` | número (entero o decimal), mayor que 0 y máximo 24 |
| `dias_semana` | entero (sin decimales), de 1 a 7 |
| `cantidad` | entero (sin decimales), de 1 a 99 |

Los booleanos no se aceptan como números.

---

## 1. Catálogo de tipos

**`GET /appliances/info`** · Desde 2.1.0

Catálogo de tipos de electrodoméstico, pensado para poblar una lista desplegable.

**Respuesta exitosa — `200 OK`**: objeto que asocia cada nombre de tipo con su potencia en W.

```json
{ "Nevera": 150, "Televisor": 100 }
```

*(Valores de ejemplo; el contenido real depende de la tabla `info_electrodomesticos`.)*

## 2. Listar electrodomésticos

**`GET /appliances`** · Desde 2.1.0

**Respuesta exitosa — `200 OK`**: arreglo de objetos Electrodoméstico del usuario; `[]` si no tiene ninguno. El orden no está garantizado.

## 3. Obtener un electrodoméstico

**`GET /appliances/{id}`** · Desde 2.1.0

**Respuesta exitosa — `200 OK`**: un objeto Electrodoméstico.

**Errores esperados**

| Código | `message` |
|--------|-----------|
| 404 | `Electrodoméstico no encontrado` |

## 4. Crear un electrodoméstico

**`POST /appliances`** · Desde 2.1.0

**Petición**: los cinco campos de las reglas de validación.

```json
{
  "nombre": "Nevera de la cocina",
  "tipo": "Nevera",
  "horas_dia": 24,
  "dias_semana": 7,
  "cantidad": 1
}
```

**Respuesta exitosa — `201 Created`**

```json
{
  "message": "Electrodoméstico añadido correctamente",
  "item": { "id_electrodomestico": 1, "nombre": "Nevera de la cocina", "...": "..." }
}
```

`item` es un objeto Electrodoméstico completo.

**Errores esperados**

| Código | `message` | Causa |
|--------|-----------|-------|
| 400 | `Se requiere un objeto JSON válido.` | Cuerpo ausente, mal formado o que no es un objeto |
| 422 | `Se requieren todos los campos.` | Faltan campos o sobran campos |
| 422 | `Datos inválidos. Revise nuevamente.` | Tipo de dato o rango incorrecto |
| 422 | `Los datos no pueden estar vacíos.` | `nombre` o `tipo` vacíos |
| 422 | `Tipo de electrodoméstico inválido.` | `tipo` no existe en el catálogo |
| 500 | `Error de conexión` | Falla de conexión con la base de datos |
| 500 | `Error al crear el electrodoméstico. Intente nuevamente` | Error interno |

## 5. Actualizar un electrodoméstico

**`PUT /appliances/{id}`** · Desde 2.1.0

Reemplaza `nombre`, `tipo`, `horas_dia`, `dias_semana` y `cantidad`. Requiere los cinco campos (no admite actualización parcial). `potencia_w` se vuelve a tomar del catálogo en cada edición.

**Respuesta exitosa — `204 No Content`**: sin cuerpo.

**Errores esperados**

| Código | `message` | Causa |
|--------|-----------|-------|
| 400 | `Se requiere un objeto JSON válido.` | Cuerpo ausente, mal formado o que no es un objeto |
| 404 | `Electrodoméstico no encontrado` | No existe o no pertenece al usuario |
| 422 | `Se requieren todos los campos.` | Faltan campos o sobran campos |
| 422 | `Datos inválidos. Revise nuevamente.` | Tipo de dato o rango incorrecto |
| 422 | `Los datos no pueden estar vacíos.` | `nombre` o `tipo` vacíos |
| 422 | `Tipo de electrodoméstico inválido.` | `tipo` no existe en el catálogo |
| 500 | `Error de conexión` | Falla de conexión con la base de datos |
| 500 | `Error al actualizar el electrodoméstico. Intente nuevamente` | Error interno |

**Orden de comprobación:** primero se valida el cuerpo y después se busca el electrodoméstico. Un cuerpo inválido sobre un `id` inexistente responde `400`/`422`, no `404`.

## 6. Eliminar un electrodoméstico

**`DELETE /appliances/{id}`** · Desde 2.1.0

**Respuesta exitosa — `204 No Content`**: sin cuerpo.

**Errores esperados**

| Código | `message` | Causa |
|--------|-----------|-------|
| 404 | `Electrodoméstico no encontrado` | No existe o no pertenece al usuario |
| 500 | `Error al eliminar el electrodoméstico. Intente nuevamente.` | Error interno |