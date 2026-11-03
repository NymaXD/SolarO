from sqlalchemy.exc import IntegrityError

from models import db, ProgresoLeccion

# Única fuente de verdad de la estructura de los módulos:
# nivel -> cantidad de lecciones.
LECCIONES_POR_NIVEL = {1: 5, 2: 7, 3: 5}


class LeccionInvalida(ValueError):
    """Nivel o lección fuera de rango, ausentes o con tipo incorrecto."""


def _entero(valor: object, campo: str) -> int:
    """Valida que el valor sea un entero y no un booleano.
    Args:
        valor (object): Valor a validar.
        campo (str): Nombre del campo (para el mensaje de error).
    Raises:
        LeccionInvalida: Si el valor no es un entero o es un booleano
    Returns:
        int: El valor convertido a entero.
    """
    if isinstance(valor, bool) or not isinstance(valor, int):
        raise LeccionInvalida(f"'{campo}' debe ser un entero")
    return valor


def _validar(datos: dict) -> tuple[int, int]:
    """Valida los datos de nivel y lección, devolviendo (nivel, lección) como enteros.

    Args:
        datos (dict): Diccionario con los campos 'nivel' y 'leccion'.

    Raises:
        LeccionInvalida: Si los datos no son válidos.

    Returns:
        tuple[int, int]: Nivel y lección como enteros.
    """
    if not isinstance(datos, dict):
        raise LeccionInvalida("El cuerpo debe ser un objeto JSON")
    
    if "nivel" not in datos or "leccion" not in datos:
        raise LeccionInvalida("Se requieren los campos 'nivel' y 'leccion'")

    nivel = _entero(datos["nivel"], "nivel")
    if nivel not in LECCIONES_POR_NIVEL:
        raise LeccionInvalida("'nivel' debe estar entre 1 y 3")

    leccion = _entero(datos["leccion"], "leccion")
    total = LECCIONES_POR_NIVEL[nivel]

    if not 1 <= leccion <= total:
        raise LeccionInvalida(f"'leccion' debe estar entre 1 y {total} para el nivel {nivel}")

    return nivel, leccion


def marcar_completada(usuario_id: str, datos: dict) -> tuple[dict, bool]:
    """Marca una lección como completada. Idempotente.

    Devuelve (resultado, creado): creado es False si ya estaba completada.
    """
    nivel, leccion = _validar(datos)

    try:
        db.session.add(
            ProgresoLeccion(
                usuario_id=usuario_id,
                nivel=nivel,
                leccion=leccion,
                completado=True,
            )
        )
        db.session.commit()
        creado = True

    except IntegrityError:
        # La restricción única ya la tenía registrada (o hubo una petición simultánea).
        db.session.rollback()
        creado = False

    return {"nivel": nivel, "leccion": leccion, "completado": True}, creado


def obtener_progreso(usuario_id: str) -> dict:
    """Progreso de los tres niveles; el porcentaje se calcula, no se almacena."""
    filas = ProgresoLeccion.query.filter_by(usuario_id=usuario_id, completado=True).all()

    por_nivel = {nivel: set() for nivel in LECCIONES_POR_NIVEL}
    for fila in filas:
        total = LECCIONES_POR_NIVEL.get(fila.nivel)
        # Se ignoran filas fuera de rango (p. ej. si un nivel reduce sus lecciones).
        if total is not None and 1 <= fila.leccion <= total:
            por_nivel[fila.nivel].add(fila.leccion)

    niveles = []
    for nivel, total in LECCIONES_POR_NIVEL.items():
        completadas = sorted(por_nivel[nivel])
        niveles.append(
            {
                "nivel": nivel,
                "completadas": completadas,
                "total": total,
                "porcentaje": round(len(completadas) / total * 100, 1),
            }
        )

    return {"niveles": niveles}