# Learn — Progreso de módulos educativos

Endpoints para registrar y consultar el progreso del usuario autenticado en los módulos educativos.

**Prefijo:** `/learn`
**Autenticación:** requerida en todos los endpoints (`Authorization: Bearer <access_token>`). El usuario se identifica por el token; nunca se envía su ID en el cuerpo.

## Estructura de los módulos

| Nivel | Lecciones | Rango válido |
|-------|-----------|--------------|
| 1     | 5         | 1–5          |
| 2     | 7         | 1–7          |
| 3     | 5         | 1–5          |

---

## POST /learn/progress

Marca una lección como completada. Es **idempotente**: marcar de nuevo una lección ya completada no produce error.

### Cuerpo

```json
{ "nivel": 2, "leccion": 4 }
```

| Campo     | Tipo    | Reglas                                                |
|-----------|---------|-------------------------------------------------------|
| `nivel`   | entero  | Requerido. 1, 2 o 3.                                  |
| `leccion` | entero  | Requerido. Dentro del rango del nivel (ver tabla).    |

Los valores booleanos, decimales o cadenas se rechazan.

### Respuestas

| Código | Cuándo                                             |
|--------|----------------------------------------------------|
| 201    | La lección se registró por primera vez.            |
| 200    | La lección ya estaba completada.                   |
| 401    | Sesión ausente o inválida.                         |
| 422    | Cuerpo ausente, campos faltantes o fuera de rango. |

**201 / 200**

```json
{ "nivel": 2, "leccion": 4, "completado": true }
```

**422**

```json
{ "message": "'leccion' debe estar entre 1 y 7 para el nivel 2" }
```

---

## DELETE /learn/progress/{nivel}/{leccion}

Desmarca una lección como completada. Es **idempotente**: desmarcar una lección que no estaba completada no produce error.

### Parámetros de ruta

| Parámetro | Tipo   | Reglas                                             |
|-----------|--------|----------------------------------------------------|
| `nivel`   | entero | 1, 2 o 3.                                          |
| `leccion` | entero | Dentro del rango del nivel (ver tabla).            |

No lleva cuerpo.

### Respuestas

| Código | Cuándo                                  |
|--------|-----------------------------------------|
| 200    | La lección quedó sin completar.         |
| 401    | Sesión ausente o inválida.              |
| 422    | `nivel` o `leccion` fuera de rango.     |

**200**

```json
{ "nivel": 2, "leccion": 4, "completado": false }
```

**422**

```json
{ "error": "'leccion' debe estar entre 1 y 7 para el nivel 2" }
```

---

## GET /learn/progress

Devuelve el progreso de los tres niveles en una sola llamada. Siempre incluye los tres niveles, aunque no tengan lecciones completadas.

### Respuestas

| Código | Cuándo                    |
|--------|---------------------------|
| 200    | Progreso del usuario.     |
| 401    | Sesión ausente o inválida.|

**200**

```json
{
  "niveles": [
    { "nivel": 1, "completadas": [1, 2], "total": 5, "porcentaje": 40.0 },
    { "nivel": 2, "completadas": [],     "total": 7, "porcentaje": 0.0 },
    { "nivel": 3, "completadas": [1],    "total": 5, "porcentaje": 20.0 }
  ]
}
```

| Campo         | Descripción                                                           |
|---------------|-----------------------------------------------------------------------|
| `completadas` | Números de lección completados, en orden ascendente.                  |
| `total`       | Cantidad de lecciones del nivel.                                      |
| `porcentaje`  | `completadas / total × 100`, con un decimal. Se calcula en cada consulta. |

### Uso en el frontend

- **Barra de progreso:** `porcentaje` de cada nivel.
- **Indicativo de «completado»:** una lección se marca si su número está en `completadas`.